
Class TeenDeviler : HDMobBase 
{
	actor latchtarget;
	double latchheight;  //as a proportion between 0 and 1
	double latchangle;  //relative to the latchtarget's angle
	double lastltangle;  //absolute, for comparison only
	double latchmass;
	
		override void postbeginplay()
		{
			super.postbeginplay();
			resize(0.8,1.2);
			A_GiveInventory("ImmunityToFire");
			lastpointinmap=pos;
			lastpointinmap=pos;
			latchmass=1.+mass*1./default.mass;
	}    
	void A_TryWimpyLatch()
		{
			if(blockingline&&CheckClimb())
			{
				setstatelabel("see");
				return;
			}	
			
		double checkrange=!!target?(target.radius*HDCONST_SQRTTWO)+meleerange:0;
		if(
			health<1
			||!target
			||target==self
			||!target.height
			||distance3dsquared(target)>checkrange*checkrange
			||absangle(angleto(target),angle)>30
			||!checkmove(0.5*(pos.xy+target.pos.xy),PCM_NOACTORS)
		){
			latchtarget=null;
			return;
		}else{
			bnodropoff=false;
			latchtarget=target;

			latchheight=(pos.z-latchtarget.pos.z)/latchtarget.height;
			lastltangle=latchtarget.angle;
			latchangle=deltaangle(lastltangle,latchtarget.angleto(self));

			setstatelabel("latched");
		}
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			(
				other!=latchtarget
				&&other!=target
			)||(
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
		if(isfrozen())return;

		//brutal force
		if(
			health>0
			&&(
				!level.ispointinlevel(pos)
				||!checkmove(pos.xy,PCM_NOACTORS)
			)
		){
			setorigin(lastpointinmap,true);
			setz(clamp(pos.z,floorz,ceilingz-height));
		}else lastpointinmap=pos;


		if(latchtarget){
			A_Face(latchtarget,0,0);


			vector3 lp=latchtarget.pos;
			bool teleported=
				abs(lp.x-pos.x)>100||
				abs(lp.y-pos.y)>100||
				abs(lp.z-pos.z)>100
			;
			

			double oldz=pos.z;
			setz(max(floorz,min(
				latchtarget.pos.z+latchtarget.height*latchheight,
				latchtarget.pos.z+latchtarget.height-height*0.6
			)));

			vector2 newxy=latchtarget.pos.xy+
				+angletovector(
					latchtarget.angle+latchangle,
					latchtarget.radius*frandom(0.9,1.)
				)
			;

			//abort if blocked
			if(
				max(
//					absangle(lastltangle,latchtarget.angle)*latchheight,
					abs(newxy.x-pos.x),
					abs(newxy.y-pos.y)
				)>frandom(10,100)
				||!checkmove(newxy,PCM_NOACTORS)
				||!level.ispointinlevel((newxy,pos.z))
				||!latchtarget
				||latchtarget.health<random(-10,1)
			){
				setz(oldz);
				if(latchtarget.health>0){
					A_Changevelocity(-5,frandom(-2,2),frandom(2,4),CVF_RELATIVE);
					forcepain(self);
				}else{
					target=lastenemy;
					setstatelabel("idle");
				}
				latchtarget=null;
			}


			if(latchtarget){
				lastltangle=latchtarget.angle;

				setorigin(
					(newxy,pos.z)+(frandom(-1,1),frandom(-1,1),frandom(-1,1))
					,!teleported
				);


				if(!random(0,30))A_Vocalize(painsound);


				double latchforce=max(latchheight,-latchheight*5)*latchmass;
				let hdp=hdplayerpawn(latchtarget);


				bool onground=
					latchtarget.bonmobj
					||latchtarget.floorz>=latchtarget.pos.z;
				double latchjump=0.;

				//fuck with the victim's pitch/angle and movement
				if(latchtarget.health>0){
					if(hdp){
						vector2 vvv=(frandom(-5,5),frandom(-4,6));
						hdp.muzzleclimb1+=vvv*latchforce;
						hdp.muzzleclimb2+=vvv*latchforce;
					}else if(
						latchtarget.bismonster
						||(
							latchtarget.player
							&&latchtarget.player.bot
						)
					){
						latchtarget.pitch=clamp(
							latchtarget.pitch+frandom(-8,8)*latchforce,-90,90
						);
						latchtarget.angle+=frandom(-8,8)*latchforce;

						//make bots and monsters thrash to try to shake it off
						latchtarget.angle+=frandom(-20,20);
					}

					if(onground){
						if(latchtarget.pos.x<pos.x)latchtarget.vel.x+=0.1*latchforce;
						else if(latchtarget.pos.x>pos.x)latchtarget.vel.x-=0.1*latchforce;
						if(latchtarget.pos.y<pos.y)latchtarget.vel.y+=0.1*latchforce;
						else if(latchtarget.pos.y>pos.y)latchtarget.vel.y-=0.1*latchforce;
					}else if(latchtarget.bfloat)latchjump=-0.1*latchforce;
				}

				//inflict damage
				if(!(level.time&1))switch(random(0,5)){
				case 0:
					latchjump=frandom(0,2)*latchforce;
					double laa=(latchangle%90)*0.2;
					if(hdp){
						hdp.muzzleclimb1+=(latchforce*frandom(0,laa),frandom(0,latchforce*5));
						hdp.muzzleclimb2+=(latchforce*frandom(0,laa),frandom(0,latchforce*5));
						hdp.muzzleclimb3+=(latchforce*frandom(0,laa),frandom(0,latchforce*5));
					}else{
						latchtarget.angle+=latchforce*frandom(0,laa*3);
						latchtarget.pitch=clamp(
							latchtarget.pitch+frandom(0,latchforce*15),-90,90
						);
					}
					latchtarget.damagemobj(
						self,self,1+int(frandom(0,8)*latchforce),"jointlock"
					);break;
				case 1:
					latchjump=frandom(1,3)*latchforce;
					latchtarget.damagemobj(
						self,self,int(frandom(0,10)*latchforce),"falling"
					);break;
				default:
					setorigin(pos+(frandom(-1,1),frandom(-1,1),frandom(-1,1))*2,true);
					latchtarget.damagemobj(
						self,self,2+int(frandom(0,8*latchforce)),"teeth"
					);break;
				}

				if(
					onground
					&&latchjump
				)latchtarget.vel.z+=latchjump;

				latchheight=clamp(latchheight+frandom(-0.01,0.014),-0.2,0.9);
			}


			NextTic();
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
		speed 6; //it's a slightly older parasite, it hasn't figured out how to move good yet, so it scoots. Slightly faster than its junior stage tho.
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
		+hdmobbase.chasealert
		+hdmobbase.climber
		+hdmobbase.climbpastdropoff
		translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
		damagefactor "Thermal",0.1; //devilers as a whole originated in a highly volcanic planet, they're functionally immune to heat.
		damagefactor "hot",0; //similarly, takes no damage if on fire.
		meleerange 126;
		minmissilechance 32;
		tag "Teen Deviler";
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
			TNT1 A 0 A_StartSound("Worm/Hurt");
			TWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
			TNT1 A 0 ThrustThing(angle*256/360, 4, 0, 0);
			TNT1 A 0 A_Jump(125,"GonnaBiteYerHeadOffRound2");
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
			TNT1 A 0 A_StartSound("Worm/Hurt");
			TWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
			TNT1 A 0 ThrustThing(angle*256/360, 16, 0, 0);
			TNT1 A 0 A_Jump(125,"GonnaBiteYerHeadOffRound2");
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
			TNT1 A 0 A_Jump(256,"StandardMelee","GonnaBiteYerHeadOffRound2","NOPERUN","Lunge");
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
			TNT1 A 0 A_Jump(65,"GonnaSPITatYou","GonnaSPITatYou","GonnaBiteYerHeadOffRound2");
			goto see;
		GonnaBiteYerHeadOffRound2:
				TWRM A 0 A_SpawnItemEx("TTail1",-5,0,0,0,0,0,0,0,0);
				TWRM A 1 A_TeenDevilDorkRandomForwardHop;
				TWRM AB 3 A_SetAngle(angle+random(-15,15));
				TWRM AB 1 A_TryWimpyLatch();
		postmelee:
				TWRM B 6 A_CustomMeleeAttack(random(1,8),"","","teeth",true);
				TWRM A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,10);} //BURRRRN
				TWRM A 0 setstatelabel("see");
		latched:
				TWRM AB random(1,2);
				TWRM A 0 A_JumpIf(!latchtarget,"pain");
				loop;
		fly:
				TWRM AB 1
					{
					A_TryWimpyLatch();
						if
							(bonmobj||floorz>=pos.z||vel.xy==(0,0))setstatelabel("land");
						else if
							(max(abs(vel.x),abs(vel.y)<3))vel.xy+=(cos(angle),sin(angle))*0.1;
					}
					wait;
		land:
				TWRM ABC 3{vel.xy*=0.8;}
				TWRM C 4{vel.xy=(0,0);}
				TWRM ABC 3 A_HDChase("melee",null);
				TWRM A 0 setstatelabel("see");
				
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
			TNT1 A 0 A_StartSound("Worm/Death");
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
		TNT1 A 0 A_StartSound("Worm/Splat");
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

