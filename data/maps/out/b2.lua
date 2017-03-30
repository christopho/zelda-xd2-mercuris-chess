-- Lua script of map out/b2.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

local zelda_chores = require("scripts/maps/zelda_chores")
local lafoo_riot = require("scripts/maps/lafoo_riot")

local bush_count = 0
local current_chore_step = -1

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()

  -- Get chores state.
  local chore_step, chore_done, all_chores_done = zelda_chores:get_chores_state()
  current_chore_step = chore_step

  -- Lock the door while the hero has not done the chores.
  local door_open = game:get_value("link_garden_door_open") == true
  link_garden_door:set_enabled(not door_open)

  -- If the hero is doing the chore 1, count the bushes
  if current_chore_step == 1 and not chore_done then
    for i = 1, 24 do
      local bush_name = "link_garden_bush_" .. i
      local bush_entity = map:get_entity(bush_name)
      if bush_entity ~= nil then
        bush_entity.on_cut = map.increase_bush_count
        bush_entity.on_lifting = map.increase_bush_count
      end
    end

  -- Else, hide all the bushes
  else
    for i = 1, 24 do
      local bush_name = "link_garden_bush_" .. i
      local bush_entity = map:get_entity(bush_name)
      if bush_entity ~= nil then
        bush_entity:remove()
      end
    end
  end

  -- Hidden chest
  if hidden_chest:is_open() then
    lens_fake_tile_1:set_enabled(false)
  end

  -- Show or hide the riot
  local riot_finished = lafoo_riot:is_finished()
  if riot_finished then
    map:remove_entities("npc_riot")
    map:remove_entities("random_walk_npc_riot")
  end

  -- Hide the Fire Rod NPC if player already has the fire rod
  local fire_rod = game:get_item("fire_rod"):get_variant()
  local has_fire_rod = fire_rod >= 1
  if has_fire_rod and npc_riot_25 ~= nil then 
    npc_riot_25:remove()
  end

end

-- Called each time a bush in Link's garden is cut.
-- When all the bushes are cut, the chore is done.
function map:increase_bush_count()
  if current_chore_step ~= 1 then
    return
  end

  bush_count = bush_count + 1

  if bush_count == 24 then
    sol.audio.play_sound("secret")
    zelda_chores:set_chore_done(true)
  end
end

-- Called when the hero talks to the mailbox.
function link_mailbox:on_interaction()
  if current_chore_step ~= 2 then
    game:start_dialog("chores.mailbox_empty")
    return
  end

  -- Give a letter to the hero if he has not got one yet.
  if game:has_item("mail_counter") and game:get_item("mail_counter"):has_amount() then
    game:start_dialog("chores.mailbox_empty")
  else
    hero:start_treasure("mail", 1)
    zelda_chores:set_chore_done(true)
  end
end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "forest_invisible_rupee_chest" then
    lens_fake_tile_1:set_enabled(false)
  end
end

function fire_rod_sensor:on_activated()
  local fire_rod = game:get_item("fire_rod"):get_variant()
  local has_fire_rod = fire_rod >= 1
  if has_fire_rod then 
    return
  end
  
  -- block hero
  local hero = map:get_hero()
  hero:freeze()
  game:set_hud_enabled(false)
  game:set_pause_allowed(false)

  local npc_movement_1 = sol.movement.create("target")
  local hero_x, hero_y = hero:get_position()
  npc_movement_1:set_speed(100)
  npc_movement_1:set_smooth(true)
  npc_movement_1:set_ignore_obstacles(true)
  npc_movement_1:set_target(hero_x + 32, hero_y)
  npc_movement_1:start(npc_riot_25, function()
    sol.timer.start(map, 800, function()
      npc_riot_25:get_sprite():set_direction(2) --left
      npc_riot_25:get_sprite():set_paused(true)
      game:start_dialog("lafoo_riot.npc_25_fire_rod", function()
        hero:unfreeze()
        hero:start_treasure("fire_rod", 1)
        game:set_hud_enabled(true)
        game:set_pause_allowed(true)
        
        local npc_movement_2 = sol.movement.create("target")
        npc_movement_2:set_speed(180)
        npc_movement_2:set_smooth(true)
        npc_movement_2:set_target(128, 24)
        --npc_movement_2:set_ignore_obstacles(true)
        npc_movement_2:start(npc_riot_25, function()
          npc_riot_25:remove()
        end)
      end)
    end)
  end)
end
