/*
Wretched
some poor soul that got suckered into a immortality ritual, now forever
cursed as a semi-corporeal ghoul to haunt the earth forever. 

Really pissed off, hurls gibs at a distance while trying to close the gap.
shakes violently in one spot, and suddenly shifts to another locations.

From time to time, will pause and stare before bum rushing you, and if it 
collides, will incap you, only temporarily tho.

Cursed to an forever unlife as an undead ghoul, it will eternally pick itself 
back up no matter how many times you knock it down. Unless you chop it to utter 
pieces, than the energy anchored within will be let loose.

Probably gonna have two variants, one anchored to a heart column, and another 
that'll spawn alongside lost souls.

Class WretchedGhoul : HDMobBase  
*/
{
	Default 
	{
		Health 400;
		Radius 16;
		Height 56;
		hdmobbase.shields 250;
		gibhealth 55;
		Mass 50;
		Speed 5;
		PainChance 136;
		//MeleeRange 125;
		Monster;
		//DropItem "GhostHealthBonus";
		RenderStyle  "Translucent";
		Alpha 0.8;
		+Floatbob;
		+FLOAT;
		+NOGRAVITY;
		+MISSILEMORE;
		+DONTFALL;
		+ThruActors
		+NOICEDEATH;
		//+shadow
		+nofear
		+frightening
		+floorclip
		+nopain
		+hdmobbase.doesntbleed
		//+NOBLOOD;
		AttackSound "wattack";
		SeeSound "wsight";
		PainSound "wpain";
		DeathSound "wdeath";
		ActiveSound "widle";
		Obituary "%o was ripped apart by a Wretched." ;
		meleerange 126;
		minmissilechance 32;
		
		}
		override void postbeginplay()
		{
			super.postbeginplay();
			voicepitch=1.+frandom(-1.,1.);
			resize(0.8,1.3);
		}

		void A_WretchedShiverWeakRight()
			{
				A_Chase();
				A_facetarget();
				A_ChangeVelocity(12,0,0,CVF_RELATIVE);
			}
		void A_WretchedShiverRight()
			{
				A_Chase();
				A_facetarget();
				A_ChangeVelocity(18,18,0,CVF_RELATIVE);
			}
		void A_WretchedShiverStrongRight()
			{
				A_Chase();
				A_facetarget();
				A_ChangeVelocity(26,0,0,CVF_RELATIVE);
			}
		void A_WretchedShiverWeakLeft()
			{
				A_Chase();
				A_facetarget();
				A_ChangeVelocity(-12,0,0,CVF_RELATIVE);
			}
		void A_WretchedShiverLeft()
			{
				A_Chase();
				A_facetarget();
				A_ChangeVelocity(-18,-18,0,CVF_RELATIVE);
			}
		void A_WretchedShiverStrongLeft()
			{
				A_Chase();
				A_facetarget();
				A_ChangeVelocity(-26,0,0,CVF_RELATIVE);
			}
		void A_WretchedShiverForward()
			{
				A_Chase();
				A_facetarget();
				ThrustThing(angle*256/360, 1, 1, 0);
			}
		void A_WretchedShiverBackwards()
			{
				A_Chase();
				A_facetarget();
				ThrustThing(angle*256/360, -1, 1, 0);
			}
		void A_WretchedEyeBeam()
			{
				A_facetarget();
				A_StartSound("wattack");
				A_SpawnProjectile("Ghostball", 40, 12,  random(1,12));//, 0, random(-1,6));
				A_SpawnProjectile("Ghostball", 40, 14,  random(1,12));//, 0, random(-1,6));
				A_AlertMonsters();
			}
		void A_WretchedRushNSmash()
			{
				A_facetarget();
				ThrustThing(angle*256/360, 5, 1, 0);
				A_Spawnitemex("WretchedTrail", 0, 0, 0, 0, 0, 0, 0, 128);
				A_ChangeVelocity(12,0,0,CVF_RELATIVE);
				A_CustomMeleeAttack(random(5,12),"Whit2","","piercing",true); //teeth
			}
			
		void A_WretchedProjectileRushNSmash()
			{
				A_facetarget();
				ThrustThing(angle*256/360, 5, 1, 0);
				A_Spawnitemex("WretchedTrail", 0, 0, 0, 0, 0, 0, 0, 128);
				A_ChangeVelocity(16,0,0,CVF_RELATIVE);
				A_SpawnProjectile("Invisismack", 40, 14 ,0, CMF_AIMDIRECTION, 0);
			}
		/*	
		void A_WretchedBashYourDamnSkullIn()
			{	
				
				if(!binvulnerable)
				{
					damagemobj(invoker,target,16,"bashing");
					A_ChangeVelocity(
						cos(pitch)*-frandom(3,6),0,sin(pitch)*frandom(3,6),
						CVF_RELATIVE
						);
					HDPlayerPawn(target).A_Incapacitated(HDPlayerPawn.HDINCAP_SCREAM,150);
				}
			}*/
		states
			{
			spwander:
				//TNT1 A 0 A_log("spwander");
				GHST AABB 2 A_HDWander();
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST AABB 2 A_HDWander();
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST AABB 2 A_HDWander();
				GHST A 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 0{
							if(!random(0,1))setstatelabel("spwander");
							else A_Recoil(-0.4);
						}//fallthrough to spawn
			Spawn:
				//TNT1 A 0 A_log("Spawn");
				GHST AB 10 A_HDLook;
				Loop;
			See:
				GHST AABB 3
					{
					 A_HDChase();
					bNOGRAVITY = TRUE; 
					}
				GHST A 0
				{
					
					if(bambush)setstatelabel("Spawn");
					else
					{
						A_SetTics(random(1,3));
						if(!random(0,5))A_StartSound("widle",CHAN_VOICE);
						if(!random(0,5))setstatelabel("spwander");
					}
				}
				loop;
			MELEE:
				TNT1 A 0 A_jump(256, "JitterInPlace","ShiftRight","ShiftLeft","ShiftZigZagForward","ShiftBackaway","ShiftWander");	
			JitterInPlace:
				//TNT1 A 0 A_log("JitterInPlace");
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				TNT1 A 1  A_jump(75, "ShiftZigZagForward","See");
				Goto See;
			ShiftRight:
				//TNT1 A 0 A_log("ShiftRight");
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST AB 2 A_WretchedShiverStrongRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				TNT1 A 1  A_jump(125, "ShiftZigZagForward","See");
				Goto See;
			ShiftLeft:
				//TNT1 A 0 A_log("ShiftLeft");
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST AB 2 A_WretchedShiverStrongLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				TNT1 A 1  A_jump(125, "ShiftZigZagForward","See");
				Goto See;
			ShiftZigZagForward:
				//TNT1 A 0 A_log("ShiftZigZagForward");
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				Goto See;
			ShiftBackaway:
				//TNT1 A 0 A_log("ShiftBackaway");
				GHST A 0 A_WretchedShiverBackwards;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverBackwards;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				GHST A 0 A_WretchedShiverBackwards;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				Goto See;
			ShiftWander:
				//TNT1 A 0 A_log("ShiftWander");
				TNT1 A 0 A_Jump (256, 1,2,3,4,5,6,7,8,9,10,11,12,13,14);
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverStrongRight;
				GHST A 0 A_WretchedShiverBackwards;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverStrongLeft;
				GHST A 0 A_WretchedShiverBackwards;
				GHST A Random(1,2) A_WretchedShiverRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverStrongLeft;
				GHST A 0 A_WretchedShiverForward;
				GHST A Random(1,2) A_WretchedShiverWeakRight;
				GHST A 0 A_WretchedShiverForward;
				GHST B Random(1,2) A_WretchedShiverWeakLeft;
				TNT1 A 1  A_jump(75, "ShiftWander","See");
				Goto See;
			Missile:
				GHST A 0 A_WretchedShiverForward;
				TNT1 A 1 A_jump(256, "IMMAFIRINGMYLASOR","SMASHUWITHMAHBONE","ShiftWander");
			IMMAFIRINGMYLASOR:
				//TNT1 A 0 A_log("IMMAFIRINGMYLASOR");
				GHST A 1 A_WretchedShiverRight;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST A 0 
					{
						A_WretchedEyeBeam();
						A_WretchedEyeBeam();
						A_ChangeVelocity(0,0,0,CVF_REPLACE);
						
					}
				GHST B 1 A_WretchedShiverLeft;
				GHST AABB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				Goto SEE;
		//	MELEE:
		//		TNT1 A 2 A_Chase();
		//		goto Missile;
			SMASHUWITHMAHBONE:
				//TNT1 A 0 A_log("SMASHUWITHMAHBONE");
				GHST F 0
				{
					bNOGRAVITY = FALSE; 
				}
				GHST A 1 A_WretchedShiverRight;
				GHST A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST AB 1 A_WretchedShiverLeft;
				GHST A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST A 1 A_WretchedShiverRight;
				GHST AB 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST ABAB 1 A_WretchedShiverLeft;
				GHST A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST ABC 1 A_WretchedShiverForward;
				GHST A 0 A_StartSound("skeleton/sight");
				GHST C 4 A_WretchedProjectileRushNSmash;
				GHST D 1 A_WretchedShiverForward;
				GHST C 4 A_WretchedProjectileRushNSmash;
				GHST D 1 A_WretchedShiverForward;
				GHST F 0
				{
					bNOGRAVITY = TRUE; 
				}
			Pain:
				TNT1 A 0 A_jump(50, "Missile");
 				GHST F 1 A_WretchedShiverRight;
				GHST F 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST F 1 A_WretchedShiverLeft;
				GHST F 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST F 1 A_WretchedShiverRight;
				GHST F 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST F 1 A_WretchedShiverLeft;
				GHST F 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				GHST F 0
				{
					bNOGRAVITY = TRUE; 
				}
				Goto See;
			Death: //ghostyboy can't properly die, you gotta gib him to fully stop him
				GHST F 0
				{
					A_Die();
					A_ChangeVelocity(0,0,0,CVF_REPLACE);
					bFloatbob = FALSE; 
					bshootable = false; 
					//A_UnsetSolid;
					bnotarget =true;
				}
				GHST F 4 ; //on death, he'll become incorporeal, hence that transluecency
				GHST G 4;
				GHST H 4;
				GHST I 4;
				GHST JKLM 4;
				GHST N 4 {bNOGRAVITY = FALSE; }
				GHST O 4;
				GHST P random(50,450);
				GHST P random(1,3)
				{ 
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
				}
				GHST P random(50,450);
				GHST P random(1,3)
				{ 
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
				}
				GHST P random(50,450);
				GHST P random(1,3)
				{ 
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
				}
				GHST P random(50,450);// That said, it should take him some time to get back up
				GHST P random(1,5)
				{ 
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
					A_SpawnItemEx("CorpseWithThePowerOfFakingDeathBalls",0,0,0,random(1,3),random(1,3),random(4,10),random(0,180));
				}
				GHST P -1 Thing_Raise(0);
				loop;
			Raise:
				GHST O 4;
				GHST N 4;
				GHST JKLM 4;
				GHST I 4;
				GHST H 4;
				GHST G 4;
				GHST F 2
				{
					bFloatbob = true; 
					bshootable = true;
					//A_UnsetSolid;
					bnotarget =false;
					bNoPain = false;
					bNOGRAVITY = TRUE;
				}
				GHST F 2; 
				#### A 0 A_Jump(256,"see");
			xDeath:
				POSS I 0 
				{
					A_SpawnItemEx("BFGNecroShard",flags:SXF_TRANSFERPOINTERS|SXF_SETMASTER,240);
					A_xScream();
					A_ChangeVelocity(0,0,0,CVF_REPLACE);
					bFloatbob = FALSE; 
				}
				tnt1 a 0 A_SpawnDebris ("GhostBlood",FALSE,random (1,5),random (1,5));
				tnt1 a 0 A_SpawnDebris ("GhostGib1",FALSE,random (1,5),random (1,3));
				tnt1 a 0 A_SpawnDebris ("GhostGib2",FALSE,random (1,5),random (1,3));
				tnt1 a 0 A_SpawnDebris ("GhostGib3",FALSE,random (1,5),random (1,3));
				tnt1 a 0 A_SpawnDebris ("GhostGib4",FALSE,random (1,5),random (1,3));
				tnt1 a 0 A_SpawnDebris ("GhostGib5",FALSE,random (1,5),random (1,3));
				tnt1 a 1 A_SpawnDebris ("GhostGib6",FALSE,random (1,5),random (1,3));
				
				stop;
			
			}
		}
		
// giblets and such

Class Ghostball : HDActor
	{
	Default
	{
	// basically if you've got any sort of armor this should never be a problem
		pushfactor 0.1;
		mass 1;
		accuracy 300;
		stamina 5;
		woundhealth 0.2;
		Radius 4;
		Height 6;
		Speed 38;
		scale 0.6;
		DamageFunction (random(4,12));
		//Damage (1,7);
		Projectile;
		damagetype "piercing";
		RenderStyle "Add";
		
		Alpha 1;
		DeathSound "WHIT";
	}
	States
	{
		Spawn:
			GBOM AE 4 Bright;
			Loop;
		Death:
			GBOM BCD 6 Bright;
			Stop;
	}
}

Class Invisismack : HDActor
	{
	Default
	{
	// basically if you've got any sort of armor this should never be a problem
		pushfactor 0.1;
		mass 1;
		accuracy 300;
		stamina 5;
		woundhealth 0.2;
		Radius 4;
		Height 6;
		Speed 28;
		scale 0.6;
		DamageFunction (random(5,7));
		//Damage (1,7);
		Projectile;
		reactiontime 3;
		damagetype "teeth";
		Alpha 1;
		DeathSound "Whit2";
	}
	States
	{
		Spawn:
			TNT1 A 0 A_countdown; 
			TNT1 A 5 Bright;
			Loop;
		Death:
			TNT1 A 1 Bright;
			Stop;
	}
}



/*
			if(!binvulnerable)
				{
					damagemobj(invoker,target,16,"bashing");
					A_ChangeVelocity(
						cos(pitch)*-frandom(3,6),0,sin(pitch)*frandom(3,6),
						CVF_RELATIVE
						);
					HDPlayerPawn(target).A_Incapacitated(HDPlayerPawn.HDINCAP_SCREAM,150);
				}
*/
Class CorpseWithThePowerOfFakingDeathBalls : HDActor
{
	default
	{
		//+nointeraction 
		+forcexybillboard 
		+bright
		projectile;
		//-NoGravity
		radius 2;
		height 2;
		
		//renderstyle "add";
		alpha 0.2; 
		scale 0.4;
		reactiontime 2;
		//translation "32:47=126:126", "168:191=112:127";
	}
	states
	{
	spawn:
		TNT1 A 0 A_countdown;
		GBOM DCBEADCBEADCBEA 1 bright nodelay A_FadeIn(0.1);
		GBOM DCBEA 1 
			{
			gravity=0.7;
			A_FadeOut(0.3);
			}
			loop;
		//wait;
	Death:
		GBOM BCD 1; 
		TNT1 A -1;// A_remove(AAPTR_DEFAULT);
 	}
}
Class GhostBlood : HDActor
{
	Default
	{
	Mass 100;
	+NOBLOCKMAP;
	+NOTELEPORT;
	Health 30;
	+ALLOWPARTICLES;
	}
	States
	{
	Spawn:
		GHG2 HIJK 8;
		Stop;
	}
}

Class GhostGib1 : HDActor
{
	Default
	{
		Mass 100;
		Health 1;
	}
	States
	{
	Spawn:
		GHGB ABCDEFGH 8;
		GHGB A -1;
	Stop;
	}
}

Class GhostGib2 : HDActor
{
	Default
	{
		Mass 100;
		Health 1;
	}
	States
	{
	Spawn:
	GHGB IJ 8;
		GHGB K -1;
	Stop;
	}
}

Class GhostGib3 : HDActor
{
	Default
	{
		Mass 100;
		Health 1;
	}
	States
	{
	Spawn:
		GHGB LMN 8;
		GHGB O -1;
	Stop;
	}
}

Class GhostGib4 : HDActor
{
	Default
	{
		Mass 100;
		Health 1;
	}
	States
	{
	Spawn:
		GHGB QRSTUVW 8;
		GHGB Q -1;
	Stop;
	}
}

Class GhostGib5 : HDActor
{	
	Default
	{
		Mass 100;
		Health 1;
	}
	States
	{
	Spawn:
		GHGB XYZ 8;
		GHG2 ABC 8;
		GHG2 C -1;
	Stop;
	}
}

Class GhostGib6 : HDActor
{	
	Default
	{
		Mass 100;
		Health 1;
		+RANDOMIZE;
	}
	States
	{
	Spawn:
		GHG2 D -1;
		GHG2 E -1;
		GHG2 F -1;
		GHG2 G -1;
	Stop;
	}
}
/*
Class HDWretchedEscapesDeath : CustomInventory
{
	Inventory.MaxAmount 1;
}
