Class BabyDeviler : HDMobBase 
{
	
	actor latchtarget;
	double latchheight;  //as a proportion between 0 and 1
	double latchangle;  //relative to the latchtarget's angle
	double lastltangle;  //absolute, for comparison only
	double latchmass;
	
		override void postbeginplay()
		{
			super.postbeginplay();
			resize(0.9,1.1);
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
		+hdmobbase.chasealert
		+cannotpush 
		+pushable
		+hdmobbase.climber
		+hdmobbase.climbpastdropoff
		Obituary "%o was broiled by a Junior Deviler." ;
		health 45;
		radius 16;
		height 12;
		mass 250;
		speed 4; //it's a lil baby parasite, it hasn't figured out how to move good yet, so it scoots.
		scale 0.3;
		Meleerange 50;
		painchance 200;
		bloodcolor "brown";
		attacksound "BWorm/Bite";
		seesound "BWorm/Sight";
		activesound "BWorm/Idle";
		painsound "Worm/Hurt";
		species "DevilerWorm";
		Gravity 1.0;
		pushfactor 0.2;
		maxstepheight 24;
		maxdropoffheight 64;
		MONSTER;
		+dontharmspecies;//+DONTHURTSPECIES;
		+NOINFIGHTING;
		translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
		damagefactor "Thermal",0; //devilers as a whole originated in a highly volcanic planet, they're literally immune to heat.
		damagefactor "hot",0; //similarly, takes no damage if on fire.
		tag "Baby Deviler";
	}
	
			void A_LilDevilBabBite()
			{
				A_facetarget();
				ThrustThingZ (0, random(5,12), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
				A_CustomMeleeAttack((2), "BWorm/Bite","","hot");
				
			}
			void A_LilDevilBabForwardScoot()
			{
				A_HDChase();
				A_facetarget();
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_LilDevilBabWanderForwardScoot()
			{
				A_HDWander();
				A_facetarget();
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,2), 1, 0);
			}
			void A_LilDevilBabRandomForwardScoot()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_LilDevilBabWanderRandomForwardScoot()
			{
				A_HDWander();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,2), 1, 0);
			}
			void A_LilDevilBabRandomForwardHop()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(5,12), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_LilDevilBabWanderRandomForwardHop()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(5,12), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,2), 1, 0);
			}
			void A_LilDevilBabRandomRunawayScoot()
			{	
				A_Pain();
				//A_HDChase();
				A_SetAngle(angle+random(-90,90));
				ThrustThingZ (0, 2, 0, 0);
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(5,10), 1, 0);
			}
			void A_LilDevilBabRandomRunawayNoPainScoot()
			{	
				A_SetAngle(angle+180);
				ThrustThingZ (0, 4, 0, 0);
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(5,10), 1, 0);
			}	
			void A_LilDevilBabisSteamingHOTLeft()
			{
				A_facetarget();
				A_ChangeVelocity(0,-1,0,CVF_RELATIVE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_LilDevilBabisSteamingHOTRight()
			{
				A_facetarget();
				A_ChangeVelocity(0,1,0,CVF_RELATIVE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_LilDevilBabTheNotsoGreatSpew()
			{
				A_HDChase();
				A_facetarget();
				//A_SetAngle(angle+random(-15,15));
				//ThrustThingZ (0, 20, 0, 0);
				A_SpawnProjectile("HDWimpyFireBall",14,0,18,2,0);
				A_SpawnProjectile("HDWimpyFireBall",14,0,23,2,0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(2,4), 1, 0);
			}
			void A_LilDevilBabTheHorribleFireVomit()
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
			TWRM A 0 A_jump(256,"WanderingScoot","WanderingHop","WanderingRandom");
		
		WanderingScoot:
			BWRM AB 5 A_LilDevilBabWanderForwardScoot();
			BWRM A 0{
				if(!random(0,1))setstatelabel("spwander");
				else A_Recoil(-0.4);
			}
			BWRM A 0 A_jump(96,"spwander","Spawn");
		WanderingHop:
			BWRM AB 5 A_LilDevilBabWanderRandomForwardHop();
			BWRM A 0{
				if(!random(0,1))setstatelabel("spwander");
				else A_Recoil(-0.4);
			}
			BWRM A 0 A_jump(96,"spwander","Spawn");
		WanderingRandom:
			BWRM AB 5 A_LilDevilBabWanderRandomForwardScoot();
			BWRM A 0{
				if(!random(0,1))setstatelabel("spwander");
				else A_Recoil(-0.4);
			}
			BWRM A 0 A_jump(96,"spwander","Spawn");
		Spawn:
			BWRM A 0 A_jump(256,"SpawnForwardScoot","SpawnRandomScoot","SpawnHop");
		SpawnForwardScoot:
			BWRM AB 1 A_HDLook;
			BWRM AB 2 A_LilDevilBabWanderForwardScoot();
			BWRM A 0 A_jump(128,"SpawnForwardScoot","SpawnRandomScoot","SpawnHop");
			BWRM A 0{
				if(bambush)setstatelabel("spawn");
				else{
						A_SetTics(random(1,3));
						if(!random(0,5))A_StartSound("BWorm/Idle",CHAN_VOICE);
						if(!random(0,5))setstatelabel("spwander");
				}
			}
			loop;
		SpawnRandomScoot:
			BWRM AB 1 A_HDLook;
			BWRM AB 2 A_LilDevilBabWanderRandomForwardScoot();
			BWRM A 0 A_jump(128,"SpawnForwardScoot","SpawnRandomScoot","SpawnHop");
			BWRM A 0{
				if(bambush)setstatelabel("spawn");
				else{
						A_SetTics(random(1,3));
						if(!random(0,5))A_StartSound("BWorm/Idle",CHAN_VOICE);
						if(!random(0,5))setstatelabel("spwander");
				}
			}
			loop;
		SpawnHop:
			BWRM AB 1 A_HDLook;
			BWRM AB 2 A_LilDevilBabWanderRandomForwardHop();
			BWRM A 0 A_jump(128,"SpawnForwardScoot","SpawnRandomScoot","SpawnHop");
			BWRM A 0{
				if(bambush)setstatelabel("spawn");
				else{
						A_SetTics(random(1,3));
						if(!random(0,5))A_StartSound("BWorm/Idle",CHAN_VOICE);
						if(!random(0,5))setstatelabel("spwander");
				}
			}
			loop;
		See:
			BWRM A 0 //restore because shenanigens
			{

				if(!checkmove(pos.xy,true)&&blockingmobj)
				{
						setorigin((pos.xy+(pos.xy-blockingmobj.pos.xy),pos.z+1),true);
				}

				blookallaround=false;
				if(!random(0,127))A_Vocalize(seesound);
				MustUnstick();

				if(CheckClimb())return;

				bnofear=target&&distance3dsquared(target)<65536.;

				if((target&&checksight(target))||!random(0,7))setstatelabel("DevilerPicksAnAction");else setstatelabel("spwander");
			}
		DevilerPicksAnAction:
			TNT1 A 0 A_Jump(256, "ScootRandom", "ScootForward", "HopForward","ScootAway");
			ScootRandom:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 1 A_LilDevilBabRandomForwardScoot;
				BWRM AB 3 A_SetAngle(angle+random(-15,15));
				TNT1 A 0 A_Jump(25, "ScootAway");
				Goto See;
			ScootForward:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 1 A_LilDevilBabForwardScoot;
				BWRM AB 3 A_SetAngle(angle+random(-15,15));
				TNT1 A 0 A_Jump(25, "ScootAway");
				Goto See;
			HopForward:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 1 A_LilDevilBabRandomForwardHop;
				BWRM AB 3 A_SetAngle(angle+random(-15,15));
				Goto See;
			ScootAway:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 2 A_LilDevilBabRandomRunawayNoPainScoot;
				BWRM AB 0 A_SetAngle(angle+random(-15,15));
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 2 A_LilDevilBabRandomRunawayNoPainScoot;
				BWRM AB 0 A_SetAngle(angle+random(-15,15));
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 2 A_LilDevilBabRandomRunawayNoPainScoot;
				BWRM AB 3 A_SetAngle(angle+random(-15,15));
				Goto See;
		Missile:
		CheckRange:
				TNT1 A 0 A_jumpIfCloser(750,"IntheRangeofBabbyFlamethrower");
				TNT1 A 0 A_jumpIfCloser(2500,"TooFarForToastingSoSitNSpit");
		IntheRangeofBabbyFlamethrower:
				TNT1 A 0 A_Jump(256,"NormalJump","GonnaBiteYerHeadOff","Lunge","SteamingHotPrep");
				Goto See;
		TooFarForToastingSoSitNSpit:
				TNT1 A 0 A_Jump(256,"NormalJump","GonnaSPITatYou");
				Goto See;
		NormalJump:
				BWRM A 0 A_jumpIfCloser(60,"Melee");
    			BWRM A 1 A_FaceTarget;
				TNT1 A 0 A_PlaySound("Worm/Hurt");
				BWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
				TNT1 A 0 ThrustThing(angle*256/360, 4, 0, 0);
				//TNT1 A 0 A_TryWimpyLatch;
		/*MidLeap:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM B 1;//A_SpawnItem ("Fix");
				//TNT1 A 0 A_CheckFloor ("Land");
				loop;
		Land:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 1 A_Stop;*/
				goto See;
		Lunge:
				BWRM A 0 A_jumpIfCloser(60,"Melee");
    			BWRM A 1 A_FaceTarget;
				TNT1 A 0 A_PlaySound("Worm/Hurt");
				BWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
				TNT1 A 0 ThrustThing(angle*256/360, 16, 0, 0);
				//BWRM A 1 A_TryWimpyLatch;
		GonnaSPITatYou:
				BWRM A 0 A_jumpIfCloser(25,"Melee");
				TNT1 A 0 A_Jump(75, "ScootAway");
				BWRM A 1 A_FaceTarget; 
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 2 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 1 bright A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 2 bright A_LilDevilBabRandomRunawayNoPainScoot();
				BWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
				BWRM A 0 bright A_LilDevilBabTheNotsoGreatSpew();
				goto see;
		SteamingHotPrep:
				BWRM A 0 A_jumpIfCloser(25,"Melee");
				TNT1 A 0 A_Jump(75, "ScootAway");
				BWRM A 1 A_FaceTarget; 
				BWRM A 0 A_jumpIfCloser(25,"Melee");
				TNT1 A 0 A_Jump(75, "ScootAway");
				BWRM A 1 A_FaceTarget; 
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 2 bright A_LilDevilBabRandomRunawayNoPainScoot();
				BWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
				BWRM A 0 bright A_LilDevilBabTheHorribleFireVomit();
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 0 bright A_LilDevilBabTheHorribleFireVomit();
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTLeft();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 1 bright A_LilDevilBabisSteamingHOTRight();
				BWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
				BWRM A 0 bright A_LilDevilBabTheHorribleFireVomit();
				goto see;
		MidLeap:
				BWRM A 0 A_SpawnItemEx("BTail1",-17,0,0,0,0,0,0,0,0);
				BWRM B 1;//A_SpawnItem ("Fix");
				//TNT1 A 0 A_CheckFloor ("Land");
				loop;
		Land:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 1 A_Stop;
				BWRM A 1 A_LilDevilBabRandomRunawayNoPainScoot;
				goto See;
		latched:
				SKUL CD 1 A_TryWimpyLatch();
				loop;
    	Melee:
				TNT1 A 0 A_Jump(256,"StandardMelee","GonnaBiteYerHeadOff","NOPERUN","Lunge");
				Goto See;
    	StandardMelee:
				BWRM B 5 A_FaceTarget;
    			BWRM A 1 A_LilDevilBabBite();
				BWRM A 10 A_LilDevilBabRandomRunawayScoot;
				TNT1 A 0 A_Jump(45,"GonnaBiteYerHeadOff");
    			Goto See;
		NOPERUN:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM B 1 A_LilDevilBabRandomRunawayNoPainScoot;
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM B 1 A_LilDevilBabRandomRunawayNoPainScoot;
				TNT1 A 0 A_Jump(45,"GonnaSPITatYou");
				goto see;
				Goto See;
		GonnaBiteYerHeadOff:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 1 A_LilDevilBabRandomForwardHop;
				BWRM AB 3 A_SetAngle(angle+random(-15,15));
				BWRM AB 1 A_TryWimpyLatch();
		postmelee:
				BWRM B 6 A_CustomMeleeAttack(random(1,8),"","","teeth",true);
				TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,10);} //BURRRRN
				BWRM A 0 setstatelabel("see");
		latched:
				BWRM EF random(1,2);
				BWRM A 0 A_JumpIf(!latchtarget,"pain");
				loop;
		fly:
				BWRM F 1
					{
					A_TryWimpyLatch();
						if
							(bonmobj||floorz>=pos.z||vel.xy==(0,0))setstatelabel("land");
						else if
							(max(abs(vel.x),abs(vel.y)<3))vel.xy+=(cos(angle),sin(angle))*0.1;
					}
					wait;
		land:
				BWRM FEH 3{vel.xy*=0.8;}
				BWRM D 4{vel.xy=(0,0);}
				BWRM ABCD 3 A_HDChase("melee",null);
				BWRM A 0 setstatelabel("see");
				
    	Pain:
				TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,30);} //yes punch the VISIBLY BURNING WORM
    			BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM B 1 A_LilDevilBabRandomRunawayScoot;
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM B 1 A_LilDevilBabRandomRunawayScoot;
    			Goto AfterPain;
			AfterPain:
				BWRM A 0 A_SpawnItemEx("BTail1",-5,0,0,0,0,0,0,0,0);
				BWRM B 1;
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
				
				//DEAD A 0 A_SpawnItem("BJawB",0,0,0);
				DEAD A 0 A_SpawnItemEx("BJawU", 0, 0, 20, 1, 0, 0, Random(0, 360), 0);
				TNT1 A 0 A_SpawnItemEx("BGut1", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut2", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut3", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut4", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut1", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut2", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut3", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				TNT1 A 0 A_SpawnItemEx("BGut4", 0, 0, 5, random(1,5), 0, 3, Random(0, 360), 128);
				
				JAWX A -1;
        	
				Stop;
			raise:
				DEAD CCBBAA 3;
				BWRM CCBBAA 3;
				BWRM A 0 A_Jump(256,"see");
	}
}

Class HDWimpyFireBallTail : HDFireball
{	
	default
	{
			damagetype "hot";
			+nointeraction 
			+forcexybillboard 
			-invisible
			renderstyle "add";
			alpha 0.5;
			scale 0.2;
	}
}
class HDWimpyFireBall:HDFireball{
	default{
			missiletype "HDWimpyFireBallTail";
			damagetype "hot";
			speed 9;
			damage (4);
			scale 0.7;
			reactiontime 35;
			
			}
	double initangleto;
	double inittangle;
	double inittz;
	vector3 initpos;
	vector3 initvel;
	virtual void A_HDIBFly(){
			roll+=10;
			if(!A_FBSeek()){
				vel*=0.99;
				A_FBFloat();
				A_Corkscrew(stamina*frandom(0,0.4));if(stamina<5)stamina++;
			}
	}
	/*
	void A_ImpSquirt(){
			roll=frandom(0,360);alpha*=0.96;scale*=frandom(1.,0.96);
			if(!tracer)return;
			double diff=max(
				absangle(initangleto,angleto(tracer)),
				absangle(inittangle,tracer.angle),
				abs(inittz-tracer.pos.z)*0.05
			);
			int dmg=int(max(0,10-diff*0.1));
			if(!tracer.player)tracer.angle+=randompick(-10,10);

			//do it again
			initangleto=angleto(tracer);
			inittangle=tracer.angle;
			inittz=tracer.pos.z;

			setorigin((pos+(tracer.pos-initpos))*0.5,true);
			if(dmg){
				tracer.A_GiveInventory("Heat",dmg);
				tracer.damagemobj(self,target,max(1,dmg>>2),"hot");
			}
	}*/
	override void postbeginplay(){
			super.postbeginplay();
			initvel=vel.unit()*0.3;
	}
	void A_FBTailAccelerate(){
			A_FBTail();
			vel+=initvel;
	}
	states{
	spawn:
			BAL1 ABABABABAB 2 A_FBTailAccelerate();
	spawn2:
			BAL1 AB 3 A_HDIBFly();
			loop;
	death:
			TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
			TNT1 A 0{
				A_Scream();
				tracer=null;
				if(blockingmobj){
						if(
							blockingmobj is "BabyDeviler"
							&&(!target||blockingmobj!=target.target)
						)blockingmobj.givebody(random(1,10));
						else{
							tracer=blockingmobj;
							blockingmobj.damagemobj(self,target,random(1,2),"electrical");
						}
				}
				if(tracer){
						initangleto=angleto(tracer);
						inittangle=tracer.angle;
						inittz=tracer.pos.z;
						initpos=tracer.pos-pos;

						//HEAD SHOT
						if(
							pos.z-tracer.pos.z>tracer.height*0.8
							&&!(tracer is "Trilobite")
							&&!(tracer is "Technorantula")
							&&!(tracer is "TechnoSpider")
							&&!(tracer is "SkullSpitter")
							&&!(tracer is "FlyingSkull")
							&&!(tracer is "Putto")
							&&!(tracer is "Yokai")
						){
							if(hd_debug)A_Log("HEAD SHOT");
							bpiercearmor=true;
						}
				}
				A_SprayDecal("BrontoScorch",radius*2);
			}
			TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,6);}
			BAL1 ABCCDDEEEEEEE 3; //A_ImpSquirt();
			stop;
	}
}

class HDWimpyFlamer : HDWimpyFireBall{ //babby flamethrower
	default{
	
			missiletype "HDWimpyFireBallTail";
			damagetype "hot";
			speed 5;
			scale 0.3;
			damage (1);
			reactiontime 3;
			gravity 0.15;
	}
	states{
	spawn:
			
			BAL1 ABABABAB 1 A_FBTail();
			goto spawn2;
	spawn2:
			BAL1 A 0 A_countdown;
			BAL1 AB 3 A_HDIBFly();
			loop;
	death:
			TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
			TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,2);}
			goto super::death;
	}
}

Class BTail1 : Actor
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
    BTAI A 5;
    Goto Death;
  Death:
	TNT1 A 0 A_SpawnItemEx("BTail2",0,0,0,0,0,0,0,0,0);
	Stop;
  }
}

Class BTail2 : Actor
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
    BTAI A 5;
    Goto Death;
  Death:
	TNT1 A 0 A_SpawnItemEx("BTail3",0,0,0,0,0,0,0,0,0);
	Stop;
  }
}

Class BTail3 : Actor
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
    BTAI A 5;
	Stop;
  }
}
//Guts

Class BGut1 : Actor
{
	Default
	{
    PROJECTILE;
    -NOGRAVITY;
    -NOBLOCKMAP;
    -NOTELEPORT;
    +RANDOMIZE;
    Radius 2;
    Damage 0;
    Speed 5;
	Scale 0.2;
   }
   States
    {
    Spawn:
        GUT1 A 0 A_SetGravity (0.5);
        GUT1 A 0 ThrustThingZ (0,random(15,30), 0, 1);
        goto See ;
    See:
        GUT1 ABCDEFGH 2;
        loop;
    Death:
        GUT1 A 1 A_SpawnItem("BFlesh1",0,0,0);
        Stop;
    }
}
Class BGut2 : Actor
{
	Default
	{
    PROJECTILE;
    -NOGRAVITY;
    -NOBLOCKMAP;
    -NOTELEPORT;
    +RANDOMIZE;
    Radius 2;
    Damage 0;
    Speed 5;
	Scale 0.4;
    }
	States
    {
    Spawn:
        GUT2 A 0 A_SetGravity (0.5);
        GUT2 A 0 ThrustThingZ (0,random(15,30), 0, 1);
        goto See ;
    See:
        GUT2 ABCDEFGH 2;
        loop;
    Death:
        GUT2 A 1 A_SpawnItem("BFlesh2",0,0,0);
        Stop;
    }
}
Class BGut3 : Actor
{
	Default
	{
    PROJECTILE;
    -NOGRAVITY;
    -NOBLOCKMAP;
    -NOTELEPORT;
    +RANDOMIZE;
    Radius 2;
    Damage 0;
    Speed 5;
	Scale 0.4;
	}
    States
    {
    Spawn:
        GUT3 A 0 A_SetGravity (0.5);
        GUT3 A 0 ThrustThingZ (0,random(15,30), 0, 1);
        goto See ;
    See:
        GUT3 ABCDEFGH 2;
        loop;
    Death:
        GUT3 A 1 A_SpawnItem("BFlesh3",0,0,0);
        Stop;
    }
}
Class BGut4 : Actor
{
	Default
	{
    PROJECTILE;
    -NOGRAVITY;
    -NOBLOCKMAP;
    -NOTELEPORT;
    +RANDOMIZE;
    Radius 2;
    Damage 0;
    Speed 5;
	Scale 0.2;
	}
    States
    {
    Spawn:
        GUT4 A 0 A_SetGravity (0.5);
        GUT4 A 0 ThrustThingZ (0,random(15,30), 0, 1);
        goto See ;
    See:
        GUT4 ABCDEFGH 2;
        loop;
    Death:
        GUT4 A 1 A_SpawnItem("BFlesh4",0,0,0);
        Stop;
    }
}
Class BFlesh1 : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.2;
	}
    States
    {
    Spawn:
        FLE3 A 1;
        TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
			FLE3 A 1;
			loop;
    }
}
Class BFlesh2 : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.2;
	}
    States
    {
    Spawn:
        FLE2 A 1;
        TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
			FLE2 A 1;
			loop;
    }
}
Class BFlesh3 : Actor
{
	Default
	{
    -NOBLOCKMAP;
	Radius 2;
	Scale 0.2;
	}
    States
    {
    Spawn:
        FLE1 A 1;
        TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
			FLE1 A 1;
			loop;
    }
}
Class BFlesh4 : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.2;
	}
    States
    {
    Spawn:
        FLE4 A 1;
			TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
			FLE4 A 1;
			loop;
    }
}

Class BJawU : Actor
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
	Scale 0.2;
	translation "208:223=19:31", "16:47=172:191", "160:167=174:191", "15:15=44:44", "238:238=189:189", "63:79=177:191";
	}
    States
    {
    Spawn:
			JAWU A 0 A_SetGravity (0.2);
        JAWU A 0 ThrustThingZ (0, 20, 0, 1);
        goto See ;
    See:
        JAWU ABCDEFGH 3;
        loop;
    Death:
        JAWU A 1 A_SpawnItem("BJawLand",0,0,0);
        Stop;
    }
}
Class BJawLand : Actor
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
			JAWJ A 1;
			TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
			JAWJ A 1;
        loop;
    }
}

Class BJawB : Actor
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


class MiniHDSmoke : HDSmoke
{
	Default
	{
	scale 0.1;
	}
}
