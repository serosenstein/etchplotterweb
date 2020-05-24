pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
function _init()
  level=1
  intro_init()
end

function do_nothing()
  -- do nothing
  return
end

function game_init()
  _update = do_nothing
  _draw = do_nothing
  music(-1)
  player = {}
  portals = {}
  enemies = {}
  exit = {}
  
  make_player()
  make_portals()
  make_enemies()
  make_exit()
  _update = game_update
  _draw = game_draw
end

function game_update()
  move_player()
  player_interact()
end

function game_draw()
  cls()
  draw_exit()
  draw_portals()
  draw_bombs()
  draw_enemies()
  draw_player()
  draw_status()
end

function dist(x1, y1, x2, y2)
  return sqrt((x2-x1)^2 + (y2-y1)^2)
end

function draw_status()
  print("level " ..level, 50, 2)
  for i = 0,player.hearts-1 do
    spr(29, 1+(10 * i), 0)
  end
  for i = 0,player.bombs-1 do
    spr(12, 120-(10 * i), 0)
  end
  line(0, 10, 128, 10, 1)
end


function make_player()
  player = {}
  player.hearts = 3
  player.bombs = 3
  player.x = rnd(100) + 10
  player.y = rnd(100) + 10
  player.spr = 1
  player.state = "running"
  player.hit_counter = 0
  player.ready = false
  step = 0
  bombs = {}
end

function make_enemies()
  enemies = {}
  for i = 0,(level-1) do
    add(enemies, make_enemy(i))
  end
end

function make_portals()
  portals = {}
  for i = 0,3 do
    add(portals, make_portal(i))
  end
end

function near(e1, e2, close)
  if dist(e1.x, e1.y, e2.x, e2.y) <= close then
    return true
  else
    return false
  end
end

function near_any(item, list, close)
  for elem in all(list) do
    if near(elem, item, close) then
      return true
    end
  end
  return false
end

function make_portal(i)
  portal = {}
  portal.index = i
  n = 0
  repeat
    n += 1
    portal.x = rnd(100) + 20
    portal.y = rnd(100) + 20
  until (n == 100) or ((not near(player, portal, 20)) and (not near_any(portal, portals, 6)))
  if (i % 2 == 0) then
    portal.spr = 6
    portal.endspr = 8
  else
    portal.spr = 9
    portal.endspr = 11
  end
  portal.countdown = 4
  return portal
end


function make_exit()
  exit = {}
  n = 0
  repeat
    n += 1
    exit.x = rnd(50) + 25
    exit.y = rnd(50) + 25
  until (n == 100) or ((not near(player, exit, 40) and not near_any(exit, portals, 20)))
  exit.spr = 19
  exit.countdown = 5
end

function make_enemy(i)
  enemy = {}
  n = 0
  repeat
    n += 1
    enemy.x = rnd(100) + 10
    enemy.y = rnd(100) + 10
  until (n == 100) or ((not near(player, enemy, 20)) and (not near_any(enemy, enemies, 10)))
  enemy.spr = 4
  enemy.hit_counter = 0
  return enemy
end
  
function draw_player()
  if ((player.state == "running") or (player.state == "teleporting")) then    
    spr(player.spr, player.x, player.y)
    if player.hit_counter > 0 then
      player.hit_counter -= 1
      if player.hit_counter == 0 then
        player.spr = 1
      end
    end
  elseif (player.state == "won") then
    print("you won!!", player.x-10, player.y+13)
    spr(player.spr, player.x-4, player.y-4, 2, 2)
    player.countdown -= 1
    if (player.countdown == 0) then
      if(player.spr == 25) then
        player.spr = 27
      else
        player.spr = 25
      end
      player.countdown = 5
      player.ready = true
    end
  elseif (player.state == "dead") then
    print("play again?", player.x-16, player.y+16)
    spr(player.spr, player.x-4, player.y-4, 2, 2)
    player.countdown -= 1
    if (player.countdown == 0) then
      player.spr += 2
      if(player.spr > 38) then
        player.spr = 38
        player.ready = true
      end
      player.countdown = 4
    end
  end  	
end

function dostep()
  player.spr += 1
  sfx(2 + (step % 2))
  step += 1
  if (player.spr == 4) then
    player.spr = 1
  end
  if player.x < 0 then
    player.x = 0
  end
  if player.x > 127-8 then
    player.x = 127-8
  end
  if player.y <= 11 then
    player.y = 11
  end
  if player.y > 127-8 then
    player.y = 127-8
  end
  move_enemies()
end

function win()
  if (player.state != "running") then
    return
  end
  music(-1)
  cls()
  sfx(6)
  player.state = "won"
  player.spr = 25
  player.countdown = 10
  for enemy in all(enemies) do
    del(enemy, enemies)
  end
  for bomb in all(bombs) do
    del(bomb, bombs)
  end
end

function move_player()
  if player.state == "won" or player.state == "dead" then
    if not player.ready then
      return
    end
    if btn() != 0 then
      if player.state == "won" then
        level += 1
      else
        level = 1
      end
      starting = true
      game_init()
    end
    return
  end 
  if ((player.state != "running") and (player.state != "teleporting")) then
    return
  end
  if btnp(5) then
    place_bomb()
    dostep()
  end
  if btnp(0) then
    player.x -= 2
    dostep()
  elseif btnp(1) then
    player.x += 2
    dostep()
  elseif btnp(2) then
    player.y -= 2
    dostep()
  elseif btnp(3) then
    player.y += 2
    dostep()
  end  
end

function player_interact()
  if player.state == "won" or player.state == "dead" then
    return
  end
  if collide(player, exit) then
    win()
  end
  touching_portal = false
  for portal in all(portals) do
    if collide(player, portal) then
      touching_portal = true
      do_portal(portal)
    end
  end
  if (not touching_portal) and (player.state == "teleporting") then
    player.state = "running"
  end
  
  for enemy in all(enemies) do
    if collide(player, enemy) then
      do_hit(enemy)
    end
  end
end

function do_hit(enemy)
  if player.hit_counter > 0 or enemy.hit_counter > 0 then
    return
  end
  if player.hearts == 1 then
    do_die()
    return
  end
  sfx(0)
  player.hearts -= 1
  player.hit_counter = 3
  player.spr = 30
  enemy.hit_counter = 60
  enemy.spr = 31
end

function do_die()
  if player.state != "running" then
    return
  end
  cls()
  sfx(15)
  player.state = "dead"
  player.spr = 32
  player.countdown = 4
  for enemy in all(enemies) do
    del(enemy, enemies)
  end
  for bomb in all(bombs) do
    del(bomb, bombs)
  end
end
  
function draw_enemies()
  if player.state == "won" or player.state == "dead" then
    return
  end
  for enemy in all(enemies) do
    spr(enemy.spr, enemy.x, enemy.y)
    if enemy.hit_counter > 0 then
      enemy.hit_counter -= 1
      if enemy.hit_counter == 0 then
        enemy.spr = 4
      end
    end
  end
end

function draw_exit()
  if player.state == "won" or player.state == "dead" then
    return
  end
  spr(exit.spr, exit.x, exit.y)
  exit.countdown -= 1
  if (exit.countdown == 0) then
    exit.countdown = 5
    exit.spr += 1
    if (exit.spr > 24) then
      exit.spr = 19
    end
  end
end

function draw_portals()
  if player.state == "won" or player.state == "dead" then
    return
  end
  for portal in all(portals) do
    spr(portal.spr, portal.x, portal.y)
    portal.countdown -= 1
    if (portal.countdown == 0) then
      portal.countdown = 4
      portal.spr += 1
      if (portal.spr > portal.endspr) then
        portal.spr -= 3
      end
    end
  end
end    

function move_enemies()
  for enemy in all(enemies) do
    if enemy.hit_counter == 0 and (rnd(100) > (20-level)) then
      if (enemy.x > player.x) then
        enemy.x -= (rnd(1 + (level * 0.05)))
      else
        enemy.x += (rnd(1 + (level * 0.05)))
      end
      if (enemy.y > player.y) then
        enemy.y -= (rnd(1 + (level * 0.05)))
      else
        enemy.y += (rnd(1 + (level * 0.05)))
      end
      if (enemy.spr < 6) then
        enemy.spr += 1
      end
      if (enemy.spr == 6) then
        enemy.spr = 4
      end
    end
  end
end

function make_bomb(x, y)
  bomb = {}
  bomb.x = x + rnd(4) - 2
  bomb.y = y + rnd(4) - 2
  bomb.spr = 12
  bomb.countdown = 60
  add(bombs, bomb)
end

function draw_bombs()
  if player.state == "won" or player.state == "dead" then
    return
  end
  for bomb in all(bombs) do
    spr(bomb.spr, bomb.x, bomb.y)
 
    bomb.countdown -= 1
    if (bomb.countdown == 0) then
      bomb.countdown = 60
      bomb.spr += 1
      if (bomb.spr < 15) then
        sfx(14)
      end
      if (bomb.spr == 15) then
        boom(bomb)
      end
      if (bomb.spr > 14) then
        bomb.countdown = 3
      end
      if (bomb.spr > 18) then
        del(bombs, bomb)
      end
    end
  end
end

function boom(bomb)
  sfx(4)
  for enemy in all(enemies) do
    if (dist(bomb.x, bomb.y, enemy.x, enemy.y) < 20) then
      sfx(5)
      del(enemies, enemy)
    end
  end
  if (dist(bomb.x, bomb.y, player.x, player.y) < 10) then
    do_die()
  end
end

function do_portal(portal)
  if player.state != "running" then
    return
  end
  player.state = "teleporting"
  sfx(7)
  if (portal.index % 2 == 0) then
    dest = portal.index + 1
  else
    dest = portal.index - 1
  end
  for destportal in all(portals) do
    if (destportal.index == dest) then
      player.x = destportal.x
      player.y = destportal.y
    end
  end
end

function place_bomb()
  if player.bombs == 0 then
    sfx(1)
    return
  end
  player.bombs -= 1
  sfx(13)
  make_bomb(player.x, player.y)
end
    
function intersect(min1, max1, min2, max2)
  return max(min1,max1) > min(min2,max2) and
         min(min1,max1) < max(min2,max2)
end

function collide(actor1,actor2)
  return intersect(actor1.x+3, actor1.x+7,
                   actor2.x+3, actor2.x+7) and
         intersect(actor1.y+2, actor1.y+8,
                   actor2.y+2, actor2.y+8)
end

-->8
function intro_init()
  intro = {}
  intro.logo_y = 130
  intro.tiki_x = -60
  intro.tiki_countdown = 3
  intro.show_text = false
  _update = intro_update
  _draw = intro_draw
  music(0)
end

function intro_update()
  if intro.logo_y > 10 then
    intro.logo_y -= 10
  end
  if (intro.logo_y == 10) and (intro.tiki_x < 34) then
    intro.tiki_countdown -= 1
    if intro.tiki_countdown == 0 then
      intro.tiki_countdown = 3
      intro.tiki_x += 5
      intro.tiki_y = 50 + (intro.tiki_x % 20) - 20
    end
  end
  if (intro.tiki_x >= 34) then
    intro.show_text = true 
    if btn() != 0 then
      game_init()
    end 
  end
end

function intro_draw()
  cls()
  spr(71, 35, intro.logo_y, 7, 3)	
  spr(64, intro.tiki_x, intro.tiki_y, 7, 8)
  if intro.show_text then
    print("arrow keys move", 34, 110)
    print("x to place bomb", 34, 120)
  end
end

__gfx__
00000000000b0b0000b0b00000bb0b00000222000002220000cccc0000cccc0000cccc000099990000999900009999000000d800000080000000000000000000
00000000000bb000000bb000000bb00000222220002222200c1dddc00cddddc00cddddc009addd9009ddad9009dddd90000d0000000d00000008000000000000
0070070000aaaa0000aaaa0000aaaa0002228282022282820cddd1c00cd1ddc00c1dd1c009ddda9009dadd9009adda9000555500005555000055550000000000
000770000aaaaaa00aaaaaa00aaaaaa002222022022220220cd1ddc00cddd1c00cddddc009dadd9009ddda9009dddd9005555550055555500555555000000000
000770000aaaaaa00aaaaaa00aaaaaa002222222022222220cddddc00cddddc00c1d1dc009dddd9009addd9009dadd9008585550085855500858555000088000
007007000a4a4aa00a4a4aa00aa4a4a000222220002222200c1dddc00cd1ddc00cddddc009addd9009dddd9009addd9005555550055555500555555000899800
000000000aaaaaa00aaaaaa00aaaaaa002022202020222020cdd1dc00cdd1dc00cddd1c009ddad9009ddad9009ddad9005555550055555500555555000899800
0000000000aaaa0000aaaa0000aaaa00020202022020202000cccc0000cccc0000cccc0000999900009999000099990000555500005555000055550000088000
0000000000088000800000080099999000009000000090000000900000009000000090000000bb0000bb0000000000000000000000000000000b0b0000099900
00000000008998000900009000899980009999900088988000889880008898800088988000000bb00bb00000000000000000000008808e00000bb00000999990
0008800008aaaa8000900900088797880889998808999998088797880887978808879788000000bbbb0000000000000000000000888888e00088880009998989
00899800899aaa9800000000087888780878987808799978089999980899999808999998000000aaaaa000000000bbbb0bbb0000888888e00888888009999099
089a998089aaaa980000000008787878087878780878987808799978087999780879997800000aaaaaaa0000000bb0bbbb00b000888888e00808088009999999
0899a98008aa9a80009009000878887808788878087888780878987808789878087898780000aaaaaaaaa000000000aaaaa0000008888e000888888000999990
008998000089980009000090088777880887778808877788088777880887778808877788000aaaaaaaaaaa0000000aaaaaaa0000008880000888888009099909
000880000008800080000008008888800088888000888880008888800088888000888880000aaaaaaaaaaa000000aaaaaaaaa000000800000088880009090909
000000000000000000000000000000000000000000000000000000000000000000000000000aa74aaa74aa00000aaaaaaaaaaa00000000000000000000000000
000000000000000000000000000000000000000000000000000005555550000000000000000aa44aaa44aa00000aaaaaaaaaaa00000000000000000000000000
000000000000000000000000000000000000000000000000000055555555000000000000000aaaaaaaaaaa00000aa74aaa74aa00000000000000000000000000
0000000000000000000000000000000000000000000000000005555555555000000000000000aaaaaaaaa000000aa44aaa44aa00000000000000000000000000
00000000000000000000000000000000000000000000000000555555555555000000000000000aaaaaaa0000000aaaaaaaaaaa00000000000000000000000000
000000000000000000000000000000000000055555500000005555555555550000000000000000aaaaa000000000aaaaaaaaa000000000000000000000000000
000000000000000000000000000000000000555555550000005500550500550000000000000000000000000000000aaaaaaa0000000000000000000000000000
0000000000000000000000000000000000055555555550000055050505050500000000000000000000000000000000aaaaa00000000000000000000000000000
00000000000000000000000000000000005555555555550000550055050055000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000055555500000005555555555550000550505050555000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000555555550000005500550500550000555555555585000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005555555555000005505050505050000555585555898000000000000000000000000000000000000000000000000000000000000000000
00000000000000000055555555555500005500550500550000555898555585000000000000000000000000000000000000000000000000000000000000000000
00000555555000000055555555555500005505050505550000555b855555bb000000000000000000000000000000000000000000000000000000000000000000
000055555555000000550055050055000055555555558500005555bb555bb5000000000000000000000000000000000000000000000000000000000000000000
000555555555500000550505050505000055558555589800000000b00000b0000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000aaaaaaaaaa0000aa00000aa00000aa0000aa0000aa0000000aaaaa00000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaa00aaaa000aaaa000aaaa00aaaa0000aa00000aaaaaaaa000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaa00aaaa000aaaa00aaaa000aaaa0000aaa000aaa000aaa000000000000000
00000000000000000000000000bbb0000000000000000000000000000aaaaaaaaaa000aaaa000aaaa0aaaa0000aaaa000aaaaa00aaa000000000000000000000
0000000bbbbbbbbb0000000000bbb00000000bbbbbbbbbbb000000000000aaaa000000aaaa000aaaaaaaa00000aaaa000aaaaa00aaaaaaa00000000000000000
0bbbbbbbbbbbbbbbbbbb000000bbb000000bbbbbbbbbbbbb000000000000aaaa000000aaaa000aaaaaaa000000aaaa0000aaa0000aaaaaaa0000000000000000
0bbbbbbbbbbbbbbbbbbbbb0000bbb0000bbbbbbbbbbbbbbb000000000000aaaa000000aaaa000aaaaaaaa00000aaaa0000000000000000aaa000000000000000
0bbbbbbbb00000bbbbbbbbbb00bbb00bbbbbbbb000000000000000000000aaaa000000aaaa000aaaa0aaaa0000aaaa0000000000aaa000aaa000000000000000
000000000000000000bbbbbbbbbbb00bbbbbb00000000000000000000000aaaa000000aaaa000aaaa00aaaa000aaaa0000000000aaaaaaaaa000000000000000
00000000000000000000bbbbbbbbb00bbbbb000000000000000000000000aaaa000000aaaa000aaaa000aaaa00aaaa00000000000aaaaaaa0000000000000000
000000000000000000000aaaaaaaaaaaaa000000000000000000000000000aa00000000aa00000aa00000aa0000aa0000000000000aaaaa00000000000000000
0000000000000000000aaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000aaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000009000999009000909999099009099999090090999009999000000000000000000
0000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000090900900909000909000090909000900090090900909000000000000000000000
000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000900090900900909009000090099000900090090900909000000000000000000000
0000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000999990900900909009990090009000900090090999009990000000000000000000
000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000900090900900909009000090009000900090090900909000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000900090999000090009999090009000900009900900909999000000000000000000
0000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaaaaaa44444aaaaaaaaaaaaaaaaaaa44444aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaaaa444444444aaaaaaaaaaaaaaa444444444aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaaa44444444444aaaaaaaaaaaaa44444444444aaaa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaa4444777444444aaaaaaaaaaa4444777444444aaa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaa4447777744444aaaaaaaaaaa4447777744444aaa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaa444477777444444aaaaaaaaa444477777444444aa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaa444477777444444aaaaaaaaa444477777444444aa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaa444447774444444aaaaaaaaa444447774444444aa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaa444444444444444aaaaaaaaa444444444444444aa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaa444444444444444aaaaaaaaa444444444444444aa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaa4444444444444aaaaaaaaaaa4444444444444aaa00000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaa4444444444444aaaaaaaaaaaa444444444444aaa00000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaaa44444444444aa4aaaaaaa4aa44444444444aaa000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaaaa444444444aaaa4aaaaa4aaaa444444444aaaa000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaaaaaa44444aaaaaaa44444aaaaaaa44444aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000aaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000aaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000aaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300003a5503f55035550005002f550275502355022550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00070000013500a3500f0500035000350003500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000a05000000180001750000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000505000000180001700000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000020650166500f6500065000650006500064000600006000000000000046000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000261501c1500a1500015000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00001b170021001b7701b1702c7702c7702c7702c7702c7700010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000
000a000027451234511d45100400004000040028451234511f45100400004002b4512645120451004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
011000201d15521155001051d1551d155001051a1551d15500105001051a1551f1551f1551f10500105001051d15521155001051d1551d155001051a1551d15500105001051f1551d1551d155001050010500105
011000101174011700117400070015740007001570000700117400070011740117401574000700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01100010213351c3351d335000050000521335213351d3351d3350000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
011000301f545215451f5451d5450c5051c5451d5450050513505155051350511505215452350523545225052350521505265451a5050c505285451d5051d5052f545005052f5052954529545295452950500505
011000300c045000050c0450c045000050c04500005000050b00500005000050000509045090050b0450000509005090000904509000090000000500005000050000500005000050c0450c0450c0450000000000
001000002075533755007053370500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
001000002105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001e255132550a2550020503255002050025520205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 08090a44
03 0b0c4344

