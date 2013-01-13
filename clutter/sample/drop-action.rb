#!/usr/bin/env ruby
#
# This sample code is a port of clutter/examples/drop-action.c.
# It is licensed under the terms of the GNU Lesser General Public
# License, version 2.1 or (at your option) later.
#
# Copyright (C) 2013  Ruby-GNOME2 Project Team
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "clutter"

Clutter.init

TARGET_SIZE = 200
HANDLE_SIZE = 128

stage = Clutter::Stage.new
stage.title = "Drop Action"
stage.signal_connect("destroy") do
  Clutter.main_quit
end

target1 = Clutter::Actor.new
target1.background_color = Clutter::Color.new(:scarlet_red_light)
target1.set_size(TARGET_SIZE, TARGET_SIZE)
target1.opacity = 64
target1.add_constraint(Clutter::AlignConstraint.new(stage, :y_axis, 0.5))
target1.x = 10
target1.reactive = true

on_target_over = lambda do |action, actor, over_p|
  final_opacity = over_p ? 128 : 64

  target = action.actor
  target.save_easing_state do
    target.easing_mode = :linear
    target.opacity = final_opacity
  end
end

target1.add_action_with_name("drop", Clutter::DropAction.new)
drop_action = target1.get_action("drop")
drop_action.signal_connect("over-in") do |_action, actor|
  on_target_over.call(_action, actor, true)
end
drop_action.signal_connect("over-out") do |_action, actor|
  on_target_over.call(_action, actor, false)
end

drag = nil
drop_successful = false
add_drag_object = lambda do |target|
  if drag.nil?
    drag = Clutter::Actor.new
    drag.background_color = Clutter::Color.new(:sky_blue_light)
    drag.set_size(HANDLE_SIZE, HANDLE_SIZE)
    drag.set_position((TARGET_SIZE - HANDLE_SIZE) / 2.0,
                      (TARGET_SIZE - HANDLE_SIZE) / 2.0)
    drag.reactive = true

    action = Clutter::DragAction.new
    action.signal_connect("drag-begin") do |_action, _actor, event_x, event_y, modifiers|
      position = _actor.position
      handle = Clutter::Actor.new
      handle.background_color = Clutter::Color.new(:sky_blue_dark)
      handle.set_size(128, 128)
      handle.set_position(event_x - position.x, event_y - position.y)
      stage.add_child(handle)

      _action.drag_handle = handle

      _actor.save_easing_state do
        _actor.easing_mode = :linear
        _actor.opacity = 128
      end

      drop_successful = true
    end
    action.signal_connect("drag-end") do |_action, _actor, event_x, event_y, modifiers|
      handle = _action.drag_handle
      printf("Drag ended at: %.0f, %.0f\n", event_x, event_y)
      _actor.save_easing_state do
        _actor.easing_mode = :linear
        _actor.opacity = 255
      end

      handle.save_easing_state do
        if drop_successful
          handle.easing_mode = :linear
          handle.opacity = 0
        else
          parent = _actor.parent

          parent.save_easing_state do
            parent.easing_mode = :linear
            parent.opacity = 255
          end

          x_pos, y_pos = _actor.transformed_position

          handle.easing_mode = :ease_out_bounce
          handle.set_position(x_pos, y_pos)
          handle.opacity = 0
        end
      end

      handle.signal_connect("transitions-completed") do |_actor|
        _actor.destroy
      end
    end

    drag.add_action(action)
  end

  parent = drag.parent
  if parent == target
    target.save_easing_state do
      target.easing_mode = :linear
      target.opacity = 255
    end
    return
  end

  if parent and parent != stage
    parent.remove_child(drag)

    parent.save_easing_state do
      parent.easing_mode :linear
      parent.opacity = 64
    end
  end
  target.add_child(drag)

  target.save_easing_state do
    target.easing_mode :linear
    target.opacity = 255
  end
end

on_target_drop = lambda do |_action, actor, event_x, event_y|
  succeeded, actor_x, actor_y = actor.transform_stage_point(event_x, event_y)
  printf("Dropped at %.0f, %.0f (screen: %.0f, %.0f)\n",
         actor_x, actor_y,
         event_x, event_y)

  drop_successful = TRUE;
  add_drag_object.call(actor)
end
drop_action.signal_connect("drop", &on_target_drop)

dummy = Clutter::Actor.new
dummy.background_color = Clutter::Color.new(:orange_dark)
dummy.set_size(640 - (2 * 10) - (2 * (TARGET_SIZE + 10)),
               TARGET_SIZE)
dummy.add_constraint(Clutter::AlignConstraint.new(stage, :x_axis, 0.5))
dummy.add_constraint(Clutter::AlignConstraint.new(stage, :y_axis, 0.5))
dummy.reactive = true

target2 = Clutter::Actor.new
target2.background_color = Clutter::Color.new(:chameleon_light)
target2.set_size(TARGET_SIZE, TARGET_SIZE)
target2.opacity = 64
target2.add_constraint(Clutter::AlignConstraint.new(stage, :y_axis, 0.5))
target2.x = 640 - TARGET_SIZE - 10
target2.reactive = true

target2.add_action_with_name("drop", Clutter::DropAction.new)
drop_action = target2.get_action("drop")
drop_action.signal_connect("over-in") do |_action, actor|
  on_target_over.call(_action, actor, true)
end
drop_action.signal_connect("over-out") do |_action, actor|
  on_target_over.call(_action, actor, false)
end
drop_action.signal_connect("drop", &on_target_drop)

stage.add_child(target1)
stage.add_child(dummy)
stage.add_child(target2)

add_drag_object.call(target1)

stage.show

Clutter.main

__END__
#include <stdlib.h>
#include <clutter/clutter.h>

#define TARGET_SIZE     200
#define HANDLE_SIZE     128

static ClutterActor *stage   = NULL;
static ClutterActor *target1 = NULL;
static ClutterActor *target2 = NULL;
static ClutterActor *drag    = NULL;

static gboolean drop_successful = FALSE;

static void add_drag_object (ClutterActor *target);

static void
on_drag_end (ClutterDragAction   *action,
             ClutterActor        *actor,
             gfloat               event_x,
             gfloat               event_y,
             ClutterModifierType  modifiers)
{
  ClutterActor *handle = clutter_drag_action_get_drag_handle (action);

  g_print ("Drag ended at: %.0f, %.0f\n",
           event_x, event_y);

  clutter_actor_save_easing_state (actor);
  clutter_actor_set_easing_mode (actor, CLUTTER_LINEAR);
  clutter_actor_set_opacity (actor, 255);
  clutter_actor_restore_easing_state (actor);

  clutter_actor_save_easing_state (handle);

  if (!drop_successful)
    {
      ClutterActor *parent = clutter_actor_get_parent (actor);
      gfloat x_pos, y_pos;

      clutter_actor_save_easing_state (parent);
      clutter_actor_set_easing_mode (parent, CLUTTER_LINEAR);
      clutter_actor_set_opacity (parent, 255);
      clutter_actor_restore_easing_state (parent);

      clutter_actor_get_transformed_position (actor, &x_pos, &y_pos);

      clutter_actor_set_easing_mode (handle, CLUTTER_EASE_OUT_BOUNCE);
      clutter_actor_set_position (handle, x_pos, y_pos);
      clutter_actor_set_opacity (handle, 0);
      clutter_actor_restore_easing_state (handle);

    }
  else
    {
      clutter_actor_set_easing_mode (handle, CLUTTER_LINEAR);
      clutter_actor_set_opacity (handle, 0);
    }

  clutter_actor_restore_easing_state (handle);

  g_signal_connect (handle, "transitions-completed",
                    G_CALLBACK (clutter_actor_destroy),
                    NULL);
}

static void
on_drag_begin (ClutterDragAction   *action,
               ClutterActor        *actor,
               gfloat               event_x,
               gfloat               event_y,
               ClutterModifierType  modifiers)
{
  ClutterActor *handle;
  gfloat x_pos, y_pos;

  clutter_actor_get_position (actor, &x_pos, &y_pos);

  handle = clutter_actor_new ();
  clutter_actor_set_background_color (handle, CLUTTER_COLOR_DarkSkyBlue);
  clutter_actor_set_size (handle, 128, 128);
  clutter_actor_set_position (handle, event_x - x_pos, event_y - y_pos);
  clutter_actor_add_child (stage, handle);

  clutter_drag_action_set_drag_handle (action, handle);

  clutter_actor_save_easing_state (actor);
  clutter_actor_set_easing_mode (actor, CLUTTER_LINEAR);
  clutter_actor_set_opacity (actor, 128);
  clutter_actor_restore_easing_state (actor);

  drop_successful = FALSE;
}

static void
add_drag_object (ClutterActor *target)
{
  ClutterActor *parent;

  if (drag == NULL)
    {
      ClutterAction *action;

      drag = clutter_actor_new ();
      clutter_actor_set_background_color (drag, CLUTTER_COLOR_LightSkyBlue);
      clutter_actor_set_size (drag, HANDLE_SIZE, HANDLE_SIZE);
      clutter_actor_set_position (drag,
                                  (TARGET_SIZE - HANDLE_SIZE) / 2.0,
                                  (TARGET_SIZE - HANDLE_SIZE) / 2.0);
      clutter_actor_set_reactive (drag, TRUE);

      action = clutter_drag_action_new ();
      g_signal_connect (action, "drag-begin", G_CALLBACK (on_drag_begin), NULL);
      g_signal_connect (action, "drag-end", G_CALLBACK (on_drag_end), NULL);

      clutter_actor_add_action (drag, action);
    }

  parent = clutter_actor_get_parent (drag);
  if (parent == target)
    {
      clutter_actor_save_easing_state (target);
      clutter_actor_set_easing_mode (target, CLUTTER_LINEAR);
      clutter_actor_set_opacity (target, 255);
      clutter_actor_restore_easing_state (target);
      return;
    }

  g_object_ref (drag);
  if (parent != NULL && parent != stage)
    {
      clutter_actor_remove_child (parent, drag);

      clutter_actor_save_easing_state (parent);
      clutter_actor_set_easing_mode (parent, CLUTTER_LINEAR);
      clutter_actor_set_opacity (parent, 64);
      clutter_actor_restore_easing_state (parent);
    }

  clutter_actor_add_child (target, drag);

  clutter_actor_save_easing_state (target);
  clutter_actor_set_easing_mode (target, CLUTTER_LINEAR);
  clutter_actor_set_opacity (target, 255);
  clutter_actor_restore_easing_state (target);

  g_object_unref (drag);
}

static void
on_target_over (ClutterDropAction *action,
                ClutterActor      *actor,
                gpointer           _data)
{
  gboolean is_over = GPOINTER_TO_UINT (_data);
  guint8 final_opacity = is_over ? 128 : 64;
  ClutterActor *target;

  target = clutter_actor_meta_get_actor (CLUTTER_ACTOR_META (action));

  clutter_actor_save_easing_state (target);
  clutter_actor_set_easing_mode (target, CLUTTER_LINEAR);
  clutter_actor_set_opacity (target, final_opacity);
  clutter_actor_restore_easing_state (target);
}

static void
on_target_drop (ClutterDropAction *action,
                ClutterActor      *actor,
                gfloat             event_x,
                gfloat             event_y)
{
  gfloat actor_x, actor_y;

  actor_x = actor_y = 0.0f;

  clutter_actor_transform_stage_point (actor, event_x, event_y,
                                       &actor_x,
                                       &actor_y);

  g_print ("Dropped at %.0f, %.0f (screen: %.0f, %.0f)\n",
           actor_x, actor_y,
           event_x, event_y);

  drop_successful = TRUE;
  add_drag_object (actor);
}

int
main (int argc, char *argv[])
{
  ClutterActor *dummy;

  if (clutter_init (&argc, &argv) != CLUTTER_INIT_SUCCESS)
    return EXIT_FAILURE;

  stage = clutter_stage_new ();
  clutter_stage_set_title (CLUTTER_STAGE (stage), "Drop Action");
  g_signal_connect (stage, "destroy", G_CALLBACK (clutter_main_quit), NULL);

  target1 = clutter_actor_new ();
  clutter_actor_set_background_color (target1, CLUTTER_COLOR_LightScarletRed);
  clutter_actor_set_size (target1, TARGET_SIZE, TARGET_SIZE);
  clutter_actor_set_opacity (target1, 64);
  clutter_actor_add_constraint (target1, clutter_align_constraint_new (stage, CLUTTER_ALIGN_Y_AXIS, 0.5));
  clutter_actor_set_x (target1, 10);
  clutter_actor_set_reactive (target1, TRUE);

  clutter_actor_add_action_with_name (target1, "drop", clutter_drop_action_new ());
  g_signal_connect (clutter_actor_get_action (target1, "drop"),
                    "over-in",
                    G_CALLBACK (on_target_over),
                    GUINT_TO_POINTER (TRUE));
  g_signal_connect (clutter_actor_get_action (target1, "drop"),
                    "over-out",
                    G_CALLBACK (on_target_over),
                    GUINT_TO_POINTER (FALSE));
  g_signal_connect (clutter_actor_get_action (target1, "drop"),
                    "drop",
                    G_CALLBACK (on_target_drop),
                    NULL);

  dummy = clutter_actor_new ();
  clutter_actor_set_background_color (dummy, CLUTTER_COLOR_DarkOrange);
  clutter_actor_set_size (dummy,
                          640 - (2 * 10) - (2 * (TARGET_SIZE + 10)),
                          TARGET_SIZE);
  clutter_actor_add_constraint (dummy, clutter_align_constraint_new (stage, CLUTTER_ALIGN_X_AXIS, 0.5));
  clutter_actor_add_constraint (dummy, clutter_align_constraint_new (stage, CLUTTER_ALIGN_Y_AXIS, 0.5));
  clutter_actor_set_reactive (dummy, TRUE);

  target2 = clutter_actor_new ();
  clutter_actor_set_background_color (target2, CLUTTER_COLOR_LightChameleon);
  clutter_actor_set_size (target2, TARGET_SIZE, TARGET_SIZE);
  clutter_actor_set_opacity (target2, 64);
  clutter_actor_add_constraint (target2, clutter_align_constraint_new (stage, CLUTTER_ALIGN_Y_AXIS, 0.5));
  clutter_actor_set_x (target2, 640 - TARGET_SIZE - 10);
  clutter_actor_set_reactive (target2, TRUE);

  clutter_actor_add_action_with_name (target2, "drop", clutter_drop_action_new ());
  g_signal_connect (clutter_actor_get_action (target2, "drop"),
                    "over-in",
                    G_CALLBACK (on_target_over),
                    GUINT_TO_POINTER (TRUE));
  g_signal_connect (clutter_actor_get_action (target2, "drop"),
                    "over-out",
                    G_CALLBACK (on_target_over),
                    GUINT_TO_POINTER (FALSE));
  g_signal_connect (clutter_actor_get_action (target2, "drop"),
                    "drop",
                    G_CALLBACK (on_target_drop),
                    NULL);

  clutter_actor_add_child (stage, target1);
  clutter_actor_add_child (stage, dummy);
  clutter_actor_add_child (stage, target2);

  add_drag_object (target1);

  clutter_actor_show (stage);

  clutter_main ();

  return EXIT_SUCCESS;
}