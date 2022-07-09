/*
class SkullColumnRealOrFakeSpawner : RandomSpawner replaces SkullColumn
{ 
	Default
	{
		DropItem "FakePosSkulCol", 255, 5;
		DropItem "HarmlessSkulCol", 255, 95;
	}
}
*/

Class HarmlessSkulCol : HDActor
{
	Default 
	{
	Radius 16;
	Height 40;
	+solid
	}
	states
	{
	Spawn:
		BFSP A -1;
		Stop;
	}
}

Class FakePosSkulCol : HDActor
{	
	Default 
	{
	Radius 16;
	Height 40;
	monster;
	speed 0;
	health 666;
	+NODAMAGE
	+BLOODLESSIMPACT
	+NOBLOOD 
	+solid
	-countkill
	}
	states
	{
		Spawn:
			BFSP A 0 
					{ 
						bisMonster = false; 
						bnotarget = true;
					}
			BFSP A 1;
		IsPlayerCloseby:
			TNT1 A 0 A_JumpIfCloser(750,"IdleAndChoose");
			goto GuessImDoingnothing;
		IdleAndChoose:
			TNT1 A 0 A_Jump(256, "SeeingIfinRange","DoinAGiggle","ShimmerAndShift","FalseMove","GuessImDoingnothing");
		DoinAGiggle:
			BFSP A 30;
			BFSP A 1 A_StartSound("PosSkul/trickery");
			TNT1 A 0 A_Jump(256, "GuessImDoingnothing", "GuessImDoingnothing", "SeeingIfinRange");
		GuessImDoingnothing:
			BFSP A 150;
			goto IsPlayerCloseby;
		FalseMove:
			BFSP A 1 A_StartSound("barrel/walk",CHAN_BODY);
			TNT1 A 0 A_Jump(256, "GuessImDoingnothing", "GuessImDoingnothing", "SeeingIfinRange");
		SeeingIfinRange:
			BFSP A 5 A_JumpIfCloser(300,"SURPRISEITSASKULL");
			TNT1 A 0 A_Jump(256, "GuessImDoingnothing", "GuessImDoingnothing", "SeeingIfinRange");
		ShimmerAndShift:
			BFSP A 1;
			TNT1 A 3 //I should probably just turn this into a function...
					{
						bisMonster = TRUE; 
						bnotarget = false;
						A_SetSpeed(28);
						A_chase();
						A_wander();
						A_StartSound("barrel/walk",CHAN_BODY);
					}
			TNT1 A 0 
					{	
						A_SetSpeed(0);
						bisMonster = FALSE; 
						bnotarget = true;
					}
			BFSP A 1;
			TNT1 A 1;
			BFSP A 1;
			TNT1 A 1;
			BFSP A 1;
			TNT1 A 1;
			BFSP A 1;
			TNT1 A 1;
			BFSP A 1;
			TNT1 A 3 
					{
						bisMonster = TRUE; 
						bnotarget = false;
						A_SetSpeed(28);
						A_chase();
						A_wander();
						A_StartSound("barrel/walk",CHAN_BODY);
					}
			TNT1 A 0
					{	
						A_SetSpeed(0);
						bisMonster = FALSE; 
						bnotarget = true;
					}
			BFSP A 1;
			TNT1 A 0 A_Jump(256, "GuessImDoingnothing", "SeeingIfinRange");
		SURPRISEITSASKULL:
			BFSP A 1;
			BFSP B 1;
			BFSP C 1;
			BFSP BCBC 2;
			TNT1 A 0 A_Spawnitemex("PossessedSkull",0,0,16,0,0,0,0, SXF_NOPOINTERS| SXF_NOCHECKPOSITION);
			TNT1 A 0 
					{ 
						bisMonster = false; 
						bnotarget = true;
					}
			BFSP D -1;
			stop;
	}
}

class PossessedSkull : HDMobBase
{
	default
	{
		mass 30;
		monster; 
		+nogravity 
		+float 
		+floatbob
		+avoidmelee 
		+lookallaround
		+pushable 
		+dontfall 
		+cannotpush 
		+thruspecies
		+hdmobbase.doesntbleed
		-telestomp -solid
		attacksound "skull/melee";
		painsound "skull/pain";
		deathsound "skull/death";
		ActiveSound "bad/active";
		Health 50;
		gibhealth 50;
		radius 8;
		height 16;
		Speed 12;
		hitobituary "%o died to a possessed.";
	}
	states
	{
		spawn:
			BAD1 ABCBA 2; 		
		spawn2:
			BAD1 ABCBA 2 A_Look();
			loop;
		see:
			BAD1 A 0{
				if(!random(0,16))vel.z+=frandom(-4,4);
			}
			BAD1 ABCBA 4{hdmobai.chase(self);}
			loop;
		missile:
			BAD1 ABCD 1 A_FaceTarget;
			BAD1 C 1 A_StartSound("putto/spit",CHAN_WEAPON);
			BAD1 D 1 A_SpawnProjectile("SkullSpit",4);
			BAD1 D 1 A_SpawnProjectile("SkullSpit",-4);
			BAD1 C 5;
			BAD1 ABCD 2;
			BAD1 ABCD 3;
			---- A 0 setstatelabel("see");
		pain:
			BAD1 BCB 1;
			BAD1 C 1 A_Recoil(4);
			BAD1 B 1 A_Pain;
			BAD1 ABCBA 2 A_FastChase();
			BAD1 ABCBA 3;
			goto missile;
		Death:
			BAD1 EFG 3 A_SpawnItemEx("HDSmoke", random(-2,2),random(-2,2),random(4,8),vel.x,vel.y,vel.z+2, flags:SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
			TNT1 A 1
				{
					A_SpawnItemEx("HDExplosion",0,0,3,vel.x,vel.y,vel.z+1,0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
					A_Scream();
					A_NoBlocking();
					if(master)master.stamina--;
				}
			TNT1 AA 1 A_SpawnItemEx("HDSmokeChunk",0,0,3,vel.x+frandom(-4,4),vel.y+frandom(-4,4),vel.z+frandom(1,6),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
			stop;
	}
}

Class SkullSpit :  HDActor
	{
		Default
		{
		// basically if you've got any sort of armor this should never be a problem
		pushfactor 0.1;
		mass 1;
		accuracy 300;
		stamina 5;
		woundhealth 0.2;
		
		Radius 2;
		Height 4;
		Speed 25;
		DamageFunction (random(3,5));
		scale 0.6;
		Projectile;
		+Randomize;
		Alpha 0.6;
		Scale 0.25;
		SeeSound "bad/attack";
		DeathSound "bad/shotx";
		renderstyle "add";
		decal "gooscorch";
		}
		States
		{
			Spawn:
				BDSX AAAABBBB 1 bright A_SpawnItemEx ("SkullSpitTrail", 0, 0, 0, 0, 0, 0, 0, 0, 0);
				loop;
			Death:
				BDSX CDE 6 bright;
				stop;
		}
	}

Class SkullSpitTrail : Actor
{
	Default
	{
	Radius 2;
	Height 4;
	+Nogravity;
	+Randomize;
	+Nointeraction;
	RenderStyle "Add";
	Alpha 0.6;
	Scale 0.25;
	}
	States
	{
	Spawn:
		BDSX AB 3 bright A_FadeOut;
		loop;
	}
}