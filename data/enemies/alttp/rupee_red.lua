local enemy = ...

local other_script = sol.main.load_file("enemies/alttp/rupee_green")
other_script(enemy)

enemy:set_damage(8)
enemy:set_money_value(20)
enemy:set_projectile_speed(240)
