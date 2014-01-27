
require "component"
require "map"
require "constants"
require "ugdk.math"
require "pyramidworks.geometry"
require "event"

local vec2 = ugdk_math.Vector2D

width = $=map.width=$
height = $=map.height=$
start_position = { "$=hero_pos.room=$", $=hero_pos.x=$, $=hero_pos.y=$ }

rooms = {
  $:for _, room in pairs(rooms) do
    { $=room.x=$, $=room.y=$, $=dump(room.name)=$ },
  $:end
}

$:for _, room in pairs(rooms) do

  $=room.name=$ = {
    width = $=room.width=$,
    height = $=room.height=$,
    matrix = $=dump(room.matrix)=$,
    neighborhood = $=dump(room.neighborhood)=$,

    recipes = {
      $:for name, recipe in pairs(room.recipes or {}) do
        ["$=name=$"] = {
          property = "$=recipe.property=$",
          params = { $=recipe.params=$ }
        },
      $:end
    },

    collision_classes = {
      $:for _, class in ipairs(room.collision_classes or {}) do
        { "$=class.class=$", "$=class.extends=$" },
      $:end
    },

    setup = function(self)
      $:for _, obj in ipairs(room.objects or {}) do
        self:MakeRecipe("$=obj.recipe=$", vec2($=obj.x=$, $=obj.y=$), "$=obj.tag or ''=$")
      $:end
      $:for trigger, event in pairs(room.events or {}) do
        $:for _, action in ipairs(event) do
          event.Register(
            "$=trigger=$",
            function ()
              $:if action.type == 'kill' then
                $:for _,tag in ipairs(action) do
                  self:WorldObjectByTag("$=tag=$"):Die()
                $:end
              $:end
            end
          )
        $:end
      $:end
    end,
  }

$:end
