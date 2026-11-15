class_name DamageResult
extends RefCounted
## What a hit or heal actually did, returned by [method HealthComponent.apply_damage]
## and [method HealthComponent.apply_heal].

## What was actually subtracted or added after all modifiers.
var final_amount: float = 0.0:
	set(value):
		final_amount = value

		if final_amount == 0:
			was_blocked = true

## How much less [member final_amount] is than the incoming amount.
var blocked_amount: float = 0.0
## Damage past 0 HP, or healing past max health.
var overkill: float = 0.0
## This hit killed the actor.
var was_lethal: bool = false
## Nothing got through, or the target was already dead.
var was_blocked: bool = false
