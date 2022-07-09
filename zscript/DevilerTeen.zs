/*
#include "zscript/MultimonsterGenerics.zs"
class DevilerJuniorHandler : EventHandler
{
	override void CheckReplacement(ReplaceEvent e)
	{
			if (!e.Replacement)
				{
					return;
				}

			switch (e.Replacement.GetClassName())
				{
				case'BabuSpectreSpawner':
				//'BabuSpectreSpawner':
					if (random[BabDevrand]() <= 115)
						{
							if (random[ManyBabDevrand]() <= 70)
							{
							e.Replacement = 'BabyWorm';
							e.Replacement = 'BabyWorm';
							e.Replacement = 'BabyWorm';
							break;
							}
							else
							{
							e.Replacement = 'BabyWorm';
							break;
							}
						}
					
					e.Replacement = 'BabuSpectreSpawner';
					break;
				case'ImpSpawner':
				//'BabuSpectreSpawner':
					if (random[BabDevrand]() <= 80)
						{
							e.Replacement = 'BabyWorm';
							e.Replacement = 'BabyWorm';
							e.Replacement = 'BabyWorm';
							break;
						}
					
					e.Replacement = 'ImpSpawner';
					break;
				}
			
	}
	
}
*/

Class TeenDeviler : HDMobBase 
{
	vector3 lastpos;
	vector3 latchpos;
	double targangle;
	actor latchtarget;
	double latchforce;
		override void postbeginplay()
		{
			super.postbeginplay();
			//resize(0.9,1.1);
			A_GiveInventory("ImmunityToFire");
			//let hdmb=HDMobBase(HDMobBase.spawnmobster(self));
			//hdmb.meleethreshold=200;
			lastpointinmap=pos;
			bbiped=bplayingid;
			resize(0.5,1.2);
			latchtarget=null;
			voicepitch=frandom(0.9,1.6);
	}    
	void A_TryWimpyLatch()
	{
		if	(
			health<1
			||!target
			||target==self
			||target.health<1
			||distance2d(target)-target.radius-radius>12
			)
		{
			latchtarget=null;
			return;
		}else{
			latchtarget=target;
			latchpos.xy=
				rotatevector(pos.xy-latchtarget.pos.xy,-latchtarget.angle).unit()
				*(latchtarget.radius+radius)
			;
			latchpos.z=frandom(8,latchtarget.height-12);
			targangle=latchtarget.angle;
			latchforce=min(0.4,mass*0.02/max(1,latchtarget.mass));
			lastpos=pos;
			setstatelabel("latched");
		}
	}
	
	override bool cancollidewith(actor other,bool passive){
		return(
			other!=latchtarget
			||(
				!latchtarget
				&&max(
					abs(other.pos.x-pos.x),
					abs(other.pos.y-pos.y)
				)>=other.radius+radius  
			)
		);
	}
	override void Die(actor source,actor inflictor,int dmgflags){
		latchtarget=null;
		super.Die(source,inflictor,dmgflags);
	}
	vector3 lastpointinmap;
	override void Tick(){
		//brutal force
		if(
			health>0
			&&(
				!level.ispointinlevel(pos)
				||!checkmove(pos.xy,PCM_DROPOFF|PCM_NOACTORS)
			)
		){
			setorigin(lastpointinmap,true);
			setz(clamp(pos.z,floorz,ceilingz-height));
		}else lastpointinmap=pos;

		if(!latchtarget||latchtarget==self||latchtarget.health<1){
			latchtarget=null;
		}
		if(latchtarget){
			A_Face(latchtarget,0,0);
			vector3 lp=latchtarget.pos;
			targangle=(targangle+latchtarget.angle)*0.5;
			lp.xy+=rotatevector(latchpos.xy,latchtarget.angle);
			latchpos.z=clamp(latchpos.z+random(-2,2),12,max(floorz,latchtarget.height-height));
			lp.z+=latchpos.z+frandom(-0.1,0.1);

			//don't interpolate teleport
			if(
				abs(lp.x-pos.x)>100||
				abs(lp.y-pos.y)>100||
				abs(lp.z-pos.z)>100
			){
				setorigin(lp,false);
			}else setorigin((lp+pos)*0.5,true);

			bool inmap=level.ispointinlevel(pos);

			//can try to bump or shake it off
			if(
				inmap
				&&(
					absangle(latchtarget.angle,targangle)>frandom(6,180)
					||floorz>pos.z
					||ceilingz<pos.z+height
					||(
						!trymove(pos.xy,true)
						&&blockingmobj!=latchtarget
					)
				)
			){
				A_Changevelocity(-6,random(-2,2),4,CVF_RELATIVE);
				latchtarget=null;
			}else{
				//fun!
				//latchtarget=bmj;
				latchtarget.A_SetAngle(frandom(
					latchtarget.angle,targangle)+random(-8,8),SPF_INTERPOLATE
				);
				latchtarget.A_SetPitch(latchtarget.pitch+random(-6,10),SPF_INTERPOLATE);
				latchtarget.vel+=(pos-lastpos)*latchforce;
				hdf.give(latchtarget,"heat",random(6,12));
				lastpos=pos;
				//lift the victim as circumstances permit
				if(
					floorz>=pos.z
					&&mass>latchtarget.mass  
				){
					latchtarget.addz(random(-1,2),true);
				}
			}
			//nexttic
			if(CheckNoDelay()){
				if(tics>0)tics--;  
				while(!tics){
					if(!SetState(CurState.NextState)){
						return;
					}
				}
			}
		}
		else super.Tick();
	}
	default
	{
		//$Category Worms;
		Obituary "%o was roasted by a Teen Deviler." ;
		health 90;
		radius 20;
		height 14;
		mass 250;
		speed 6; //it's a lil baby parasite, it hasn't figured out how to move good yet, so it scoots. Slightly faster than its junior stage tho.
		scale 0.4;
		Meleerange 50;
		painchance 200;
		species "DevilerWorm";
		bloodcolor "brown";
		attacksound "BWorm/Bite";
		seesound "BWorm/Sight";
		activesound "BWorm/Idle";
		painsound "Worm/Hurt";
		Gravity 1.0;
		MONSTER;
		+dontharmspecies;//+DONTHURTSPECIES;
		+NOINFIGHTING;
		+cannotpush; 
		+pushable;
		translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
		damagefactor "Thermal",0.1; //devilers as a whole originated in a highly volcanic planet, they're functionally immune to heat.
		damagefactor "hot",0; //similarly, takes no damage if on fire.
		meleerange 126;
		minmissilechance 32;
	}
	
			void A_TeenDevilDorkDiggyDiggy()
			{
				bShootable=False;
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(2,6), 0, 0);
				spawn("Roc1",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc2",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc3",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDWimpyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc1",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc2",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc3",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDWimpyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
			}
			void A_TeenDevilDorkPOPOUTANDBITEYA()
			{
				bShootable=True;
				A_facetarget();
				ThrustThingZ (0, 7, 0, 0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDWimpyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDWimpyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDWimpyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDWimpyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				ThrustThing(angle*256/360, 3, 1, 0);
				A_CustomMeleeAttack(random(5,10), "BWorm/Bite","","teeth",true);
			}
			
			void A_TeenDevilDorkBite()
			{
				A_facetarget();
				ThrustThingZ (0, random(2,10), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
				A_CustomMeleeAttack(random(5,10), "BWorm/Bite","","teeth",true);
			}
			void A_TeenDevilDorkForwardScoot()
			{
				A_HDChase();
				A_facetarget();
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_TeenDevilDorkRandomForwardScoot()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_TeenDevilDorkRandomForwardHop()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(1,3), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			
			void A_TeenDevilDorkWanderingRandomForwardHop()
			{
				A_HDWander();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(1,3), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			
			void A_TeenDevilDorkTHEBIGDIVE()
			{
				A_HDChase();
				A_facetarget();
				ThrustThingZ (0, random(15,20), 0, 0);
			}
			
			void A_TeenDevilDorkRandomRunawayScoot()
			{	
				A_Pain();
				//A_HDChase();
				A_SetAngle(angle+random(-90,90));
				ThrustThingZ (0, 2, 0, 0);
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(5,10), 1, 0);
			}
			void A_TeenDevilDorkRandomRunawayNoPainScoot()
			{	
				A_SetAngle(angle+180);
				ThrustThingZ (0, 4, 0, 0);
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(5,10), 1, 0);
			}	
			void A_TeenDevilDorkisSteamingHOTLeft()
			{
				A_facetarget();
				A_ChangeVelocity(0,-1,0,CVF_RELATIVE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_TeenDevilDorkisSteamingHOTRight()
			{
				A_facetarget();
				A_ChangeVelocity(0,1,0,CVF_RELATIVE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_TeenDevilDorkThePrettyGoodSpit()
			{
				A_HDChase();
				A_facetarget();
				//A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, 9, 0, 0);
				A_SpawnProjectile("HDImpBall",14,0,18,2,0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				//ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_TeenDevilDorkTheHorribleFireVomit()
			{
				A_HDChase();
				A_facetarget();
				//A_SetAngle(angle+random(-15,15));
				//ThrustThingZ (0, 20, 0, 0);
				A_SpawnProjectile("HDWimpyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				A_SpawnProjectile("HDWimpyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				A_SpawnProjectile("HDWimpyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				//A_SpawnProjectile("HDWimpyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				//A_SpawnProjectile("HDWimpyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
	States
	{
	spwander:
		TWRM AB 5 A_HDWander();
		TWRM A 0{
			if(!random(0,1))setstatelabel("spwander");
			else A_Recoil(-0.4);
		}//fallthrough to spawn
		TWRM A 0 A_jump(96,"spwanderBoing","Spawn");
	spwanderBoing: 
		TWRM AB 5 A_TeenDevilDorkWanderingRandomForwardHop();
		TWRM A 0{
			if(!random(0,1))setstatelabel("spwander");
			else A_Recoil(-0.4);
		}//fallthrough to spawn
	Spawn:
		TWRM A 8 A_HDLook;
		TWRM A 0{
			if(bambush)setstatelabel("spawn");
			else{
				A_SetTics(random(1,3));
				if(!random(0,5))A_StartSound("BWorm/Idle",CHAN_VOICE);
				if(!random(0,5))setstatelabel("spwander");
			}
		}loop;
	See:
		TNT1 A 0 {bShootable=True;}
		TNT1 A 0 A_Jump(256, "ScootRandom", "ScootForward", "HopForward","ScootAway");
		ScootRandom:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM AB 1 A_TeenDevilDorkRandomForwardScoot;
			TWRM AB 3 A_SetAngle(angle+random(-15,15));
			TNT1 A 0 A_Jump(50, "ScootAway", "GonnaDiggyDiggy");
			Goto See;
		ScootForward:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM AB 1 A_TeenDevilDorkForwardScoot;
			TWRM AB 3 A_SetAngle(angle+random(-15,15));
			TNT1 A 0 A_Jump(50, "ScootAway", "GonnaDiggyDiggy");
			Goto See;
		HopForward:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM AB 1 A_TeenDevilDorkRandomForwardHop;
			TWRM AB 3 A_SetAngle(angle+random(-15,15));
			Goto See;
		ScootAway:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM AB 2 A_TeenDevilDorkRandomRunawayNoPainScoot;
			TWRM AB 0 A_SetAngle(angle+random(-15,15));
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM AB 2 A_TeenDevilDorkRandomRunawayNoPainScoot;
			TWRM AB 0 A_SetAngle(angle+random(-15,15));
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM AB 2 A_TeenDevilDorkRandomRunawayNoPainScoot;
			TWRM AB 3 A_SetAngle(angle+random(-15,15));
			Goto See;
		GonnaDiggyDiggy:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 2 A_TeenDevilDorkTHEBIGDIVE();
			TWRM AB 6 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
		IAMTHEDIGGIESTWORM:
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomForwardScoot();
						}
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomRunawayScoot();
						}
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomRunawayScoot();
						}
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomForwardScoot();
						}
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomForwardScoot();
						}
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomRunawayScoot();
						}
			TNT1 A 4	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkRandomForwardScoot();
						}
			TNT1 A 0 A_jump(70, "IAMTHEDIGGIESTWORM", "OkayIllBiteYourButt");
		OkayIllBiteYourButt:
			TNT1 A 2	{
					A_TeenDevilDorkDiggyDiggy();
					A_TeenDevilDorkForwardScoot();
						}
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 2 A_TeenDevilDorkPOPOUTANDBITEYA();
			goto See;
			
	Missile:
	CheckRange:
			TNT1 A 0 {bShootable=True;}
			TNT1 A 0 A_jumpIfCloser(750,"IntheRangeofTeenGoodFlamethrower");
			TNT1 A 0 A_jumpIfCloser(2500,"TooFarForToastingSoSitNSpit");
	IntheRangeofTeenGoodFlamethrower:
			TNT1 A 0 A_Jump(256,"NormalJump","Lunge","SteamingHotPrep");
			Goto See;
	TooFarForToastingSoSitNSpit:
			TNT1 A 0 A_Jump(256,"NormalJump","GonnaSPITatYou");
			Goto See;
	NormalJump:
			TWRM A 0 A_jumpIfCloser(60,"Melee");
    		TWRM A 1 A_FaceTarget;
			TNT1 A 0 A_PlaySound("Worm/Hurt");
			TWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
			TNT1 A 0 ThrustThing(angle*256/360, 4, 0, 0);
			TNT1 A 0 A_TryWimpyLatch;
		MidLeap:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM B 1;//A_SpawnItem ("Fix");
			TNT1 A 0 A_CheckFloor ("Land");
			loop;
		Land:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 1 A_Stop;
			goto See;
		Lunge:
			TWRM A 0 A_jumpIfCloser(60,"Melee");
    		TWRM A 1 A_FaceTarget;
			TNT1 A 0 A_PlaySound("Worm/Hurt");
			TWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
			TNT1 A 0 ThrustThing(angle*256/360, 16, 0, 0);
			TWRM A 1 A_TryWimpyLatch;
		GonnaSPITatYou:
			TWRM A 0 A_jumpIfCloser(25,"Melee");
			TNT1 A 0 A_Jump(75, "ScootAway");
			TWRM A 1 A_FaceTarget; 
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 2 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 1 bright A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 2 bright A_TeenDevilDorkRandomRunawayNoPainScoot();
			TWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
			TWRM A 0 bright A_TeenDevilDorkThePrettyGoodSpit();
			goto see;
		SteamingHotPrep:
			TWRM A 0 A_jumpIfCloser(25,"Melee");
			TNT1 A 0 A_Jump(75, "ScootAway");
			TWRM A 1 A_FaceTarget; 
			TWRM A 0 A_jumpIfCloser(25,"Melee");
			TNT1 A 0 A_Jump(75, "ScootAway");
			TWRM A 1 A_FaceTarget; 
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 2 bright A_TeenDevilDorkRandomRunawayNoPainScoot();
			TWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
			TWRM A 0 bright A_TeenDevilDorkTheHorribleFireVomit();
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 0 bright A_TeenDevilDorkTheHorribleFireVomit();
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTLeft();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 1 bright A_TeenDevilDorkisSteamingHOTRight();
			TWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			TWRM A 0 bright A_TeenDevilDorkTheHorribleFireVomit();
			goto see;
		MidLeap:
			TWRM A 0 A_SpawnItemEx("TTail1",-17,0,0,0,0,0,0,0,0);
			TWRM B 1;//A_SpawnItem ("Fix");
			TNT1 A 0 A_CheckFloor ("Land");
			loop;
		Land:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 1 A_Stop;
			TWRM A 1 A_TeenDevilDorkRandomRunawayNoPainScoot;
			goto See;
		latched:
			SKUL CD 1 A_TryWimpyLatch();
			loop;
    	Melee:
			TNT1 A 0 A_Jump(256,"StandardMelee","NOPERUN","Lunge");
			Goto See;
    	StandardMelee:
			TWRM B 5 A_FaceTarget;
    		TWRM A 1 A_TeenDevilDorkBite();
			TWRM A 10 A_TeenDevilDorkRandomRunawayScoot;
    		Goto See;
		NOPERUN:
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM B 1 A_TeenDevilDorkRandomRunawayNoPainScoot;
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM B 1 A_TeenDevilDorkRandomRunawayNoPainScoot;
			TNT1 A 0 A_Jump(45,"GonnaSPITatYou");
			goto see;
    	Pain:
			TNT1 A 0 {bShootable=True;}
			TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,30);} //yes punch the VISIBLY BURNING WORM
    		TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM B 1 A_TeenDevilDorkRandomRunawayScoot;
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM B 1 A_TeenDevilDorkRandomRunawayScoot;
    		Goto AfterPain;
		AfterPain:
			TNT1 A 0 {bShootable=True;}
			TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
			TWRM B 1;
			TNT1 A 0 A_CheckFloor ("See");
			loop;
        Death:
			//TNT1 A 0 ThrustThing(angle*256/360, 0, 0, 0);
			TWBA ABCB 1;
			TNT1 A 0 A_PlaySound("Worm/Death");
			TWBA ABCBABCBABCBABCB 1;
			DEAD AAAA 1;
			DEAD BBBB 1;
			DEAD C 1;
			
			//DEAD A 0 A_SpawnItem("TJawB",0,0,0);
			DEAD A 0 A_SpawnItemEx("TJAWT", 0, 0, 20, 1, 0, 0, Random(0, 360), 0);
			TNT1 A 0 A_SpawnItemEx("BGut1", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut2", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut3", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut4", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut1", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut2", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut3", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			TNT1 A 0 A_SpawnItemEx("BGut4", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
			
			JAWT A -1;
        	
			Stop;
	}
}

Class TTail1 : Actor
{
	Default
	{
  Scale 0.25;
  +NOGRAVITY;
  translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
  }
  States
  {
  Spawn:
    TTAI A 5;
    Goto Death;
  Death:
	TNT1 A 0 A_SpawnItemEx("TTAI2",0,0,0,0,0,0,0,0,0);
	Stop;
  }
}

Class TTAI2 : Actor
{
	Default
	{
  Scale 0.2;
  +NOGRAVITY;
  translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
	}
 States
  {
  Spawn:
    TTAI A 5;
    Goto Death;
  Death:
	TNT1 A 0 A_SpawnItemEx("TTAI3",0,0,0,0,0,0,0,0,0);
	Stop;
  }
}

Class TTAI3 : Actor
{
	Default
	{
  Scale 0.15;
  +NOGRAVITY;
  translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
	}
  States
  {
  Spawn:
    TTAI A 5;
	Stop;
  }
}
//Guts


Class TJAWT : Actor
{
	Default
	{
    PROJECTILE;
    -NOGRAVITY;
    -NOBLOCKMAP;
    -NOTELEPORT;
	Gravity 0.2;
    Radius 2;
    Damage 0;
	Scale 0.4;
	translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
	}
    States
    {
    Spawn:
		JAWT A 0 A_SetGravity (0.2);
        JAWT A 0 ThrustThingZ (0, 20, 0, 1);
        goto See ;
    See:
        JAWT ABCDEFGH 3;
        loop;
    Death:
        JAWT A 1 A_SpawnItem("TJawLand",0,0,0);
        Stop;
    }
}
Class TJawLand : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.4;
	translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
	}
    States
    {
    Spawn:
		JAWJ A 1;
		TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
		JAWJ A 1;
        loop;
    }
}

Class TJawB : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.2;
	translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
	}
    States
    {
    Spawn:
        JAWX A 1;
        goto Spawn;
    }
}

