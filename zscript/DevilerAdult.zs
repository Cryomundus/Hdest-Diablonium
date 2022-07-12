Class AdultDeviler : HDMobBase 
{
	actor latchtarget;
	double latchheight;  //as a proportion between 0 and 1
	double latchangle;  //relative to the latchtarget's angle
	double lastltangle;  //absolute, for comparison only
	double latchmass;
	
		override void postbeginplay()
		{
			super.postbeginplay();
			resize(0.9,1.5);
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
	
	override double bulletshell(vector3 hitpos,double hitangle){
		return frandom(3,7);
	}
	override double bulletresistance(double hitangle){
		return max(0,frandom(0.8,1.)-hitangle*0.008);
	}
	default
	{
		//$Category Worms;
		Obituary "%o was incinerated by an Adult Deviler." ;
		health 400;
		hdmobbase.shields 150;
		radius 14;
		height 40;
		mass 1250;
		speed 10; //it's a adult parasite, it's realized it really can't move good, so it scoots. Despite that, its faster than its teen stage tho.
		scale 0.8;
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
		damagefactor "balefire",0.3;
		damagefactor "cold",1.4; //originating from a volcanic planet, they have a bit of a weakness to cold.
		damagefactor "Thermal",0.1; //devilers as a whole originated in a highly volcanic planet, they're functionally immune to heat.
		damagefactor "hot",0; //similarly, takes no damage if on fire.
		meleerange 126;
		minmissilechance 32;
		translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
		tag "Adult Deviler";
	}
	
			void A_BigBoyDevilerDiggyDiggy()
			{
				bShootable=False;
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(6,14), 0, 0);
				spawn("Roc1",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc2",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc3",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc1",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc2",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc3",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
			}
			void A_BigBoyDevilerPOPOUTANDBITEYA()
			{
				bShootable=True;
				A_facetarget();
				ThrustThingZ (0, 10, 0, 0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				spawn("Roc4",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc5",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("Roc6",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(-5,12),frandom(0,6),frandom(-5,22),2,0);
				ThrustThing(angle*256/360, 3, 1, 0);
				A_CustomMeleeAttack(random(12,20), "BWorm/Bite","","teeth",true);
			}
			
			void A_BigBoyDevilerChomp()
			{
				A_facetarget();
				ThrustThingZ (0, random(6,14), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
				A_CustomMeleeAttack(random(12,20), "BWorm/Bite","","teeth",true);
			}
			void A_BigBoyDevilerForwardScoot()
			{
				A_HDChase();
				A_facetarget();
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			void A_BigBoyDevilerRandomForwardScoot()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			void A_BigBoyDevilerRandomForwardHop()
			{
				A_HDChase();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(6,14), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			
			void A_BigBoyDevilerWanderingRandomForwardHop()
			{
				A_HDWander();
				A_facetarget();
				A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, random(6,14), 0, 0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			
			void A_BigBoyDevilerTHEBIGDIVE()
			{
				A_HDChase();
				A_facetarget();
				ThrustThingZ (0, random(20,35), 0, 0);
			}
			
			void A_BigBoyDevilerRandomRunawayScoot()
			{	
				A_Pain();
				//A_HDChase();
				A_SetAngle(angle+random(-90,90));
				ThrustThingZ (0, 7, 0, 0);
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(5,10), 1, 0);
			}
			void A_BigBoyDevilerRandomRunawayNoPainScoot()
			{	
				A_SetAngle(angle+180);
				ThrustThingZ (0, 7, 0, 0);
				spawn("MiniHDSmoke",pos,ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(5,10), 1, 0);
			}	
			void A_BigBoyDevilerisSteamingHOTLeft()
			{
				A_facetarget();
				A_ChangeVelocity(0,-1,0,CVF_RELATIVE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			void A_BigBoyDevilerisSteamingHOTRight()
			{
				A_facetarget();
				A_ChangeVelocity(0,1,0,CVF_RELATIVE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			void A_BigBoyDevilerThePrettyGoodSpit()
			{
				A_HDChase();
				A_facetarget();
				//A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, 12, 0, 0);
				A_SpawnProjectile("BigBoyBlazerShot",38,0,2,0,0);
				A_SpawnProjectile("BigBoyBlazerShot",38,0,-2,0,0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				//ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			void A_BigBoyDevilerSpitOutTHEBOI()
			{
				A_HDChase();
				A_facetarget();
				//A_SetAngle(angle+random(-15,15));
				ThrustThingZ (0, 12, 0, 0);
				A_SpawnProjectile("HDBigBoyEggSpit",38,0,2,0,0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				//ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
			void A_BigBoyDevilerTheHorribleFireVomit()
			{
				A_HDChase();
				A_facetarget();
				//A_SetAngle(angle+random(-15,15));
				//ThrustThingZ (0, 20, 0, 0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				A_SpawnProjectile("HDBigBoyFlamer",frandom(10,22),frandom(0,12),frandom(10,22),2,0);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
				ThrustThing(angle*256/360, random(1,3), 1, 0);
			}
	States
	{
	spwander:
		AWRM AB 5 A_HDWander();
		AWRM A 0{
			if(!random(0,1))setstatelabel("spwander");
			else A_Recoil(-0.4);
		}//fallthrough to spawn
		AWRM A 0 A_jump(96,"spwanderBoing","Spawn");
	spwanderBoing: 
		AWRM AB 5 A_BigBoyDevilerWanderingRandomForwardHop();
		AWRM A 0{
			if(!random(0,1))setstatelabel("spwander");
			else A_Recoil(-0.4);
		}//fallthrough to spawn
	Spawn:
		AWRM A 8 A_HDLook;
		AWRM A 0{
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
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM AB 1 A_BigBoyDevilerRandomForwardScoot;
			AWRM AB 3 A_SetAngle(angle+random(-15,15));
			TNT1 A 0 A_Jump(50, "ScootAway", "GonnaDiggyDiggy");
			Goto See;
		ScootForward:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM AB 1 A_BigBoyDevilerForwardScoot;
			AWRM AB 3 A_SetAngle(angle+random(-15,15));
			TNT1 A 0 A_Jump(50, "ScootAway", "GonnaDiggyDiggy");
			Goto See;
		HopForward:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM AB 1 A_BigBoyDevilerRandomForwardHop;
			AWRM AB 3 A_SetAngle(angle+random(-15,15));
			Goto See;
		ScootAway:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM AB 2 A_BigBoyDevilerRandomRunawayNoPainScoot;
			AWRM AB 0 A_SetAngle(angle+random(-15,15));
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM AB 2 A_BigBoyDevilerRandomRunawayNoPainScoot;
			AWRM AB 0 A_SetAngle(angle+random(-15,15));
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM AB 2 A_BigBoyDevilerRandomRunawayNoPainScoot;
			AWRM AB 3 A_SetAngle(angle+random(-15,15));
			Goto See;
		GonnaDiggyDiggy:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 2 A_BigBoyDevilerTHEBIGDIVE();
			AWRM AB 6 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
		IAMTHEDIGGIESTWORM:
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomForwardScoot();
						}
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomRunawayScoot();
						}
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomRunawayScoot();
						}
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomForwardScoot();
						}
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomForwardScoot();
						}
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomRunawayScoot();
						}
			TNT1 A 4	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerRandomForwardScoot();
						}
			TNT1 A 0 A_jump(70, "IAMTHEDIGGIESTWORM", "OkayIllBiteYourButt");
		OkayIllBiteYourButt:
			TNT1 A 2	{
					A_BigBoyDevilerDiggyDiggy();
					A_BigBoyDevilerForwardScoot();
						}
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 2 A_BigBoyDevilerPOPOUTANDBITEYA();
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
			AWRM A 0 A_jumpIfCloser(60,"Melee");
    			AWRM A 1 A_FaceTarget;
			AWRM A 0 A_PlaySound("Worm/Hurt");
			AWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
			AWRM A 0 ThrustThing(angle*256/360, 4, 0, 0);
			AWRM A 0 A_Jump(125,"GonnaBiteYerHeadOffRound2");
		MidLeap:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM B 1;//A_SpawnItem ("Fix");
			AWRM A 0 A_CheckFloor ("Land");
			loop;
		Land:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 1 A_Stop;
			goto See;
		Lunge:
			AWRM A 0 A_jumpIfCloser(60,"Melee");
    			AWRM A 1 A_FaceTarget;
			AWRM A 0 A_PlaySound("Worm/Hurt");
			AWRM A 0 ThrustThingZ (0, random(6,18), 0, 0);
			AWRM A 0 ThrustThing(angle*256/360, 16, 0, 0);
			AWRM A 0 A_Jump(125,"GonnaBiteYerHeadOffRound2");
		GonnaSPITatYou:
			AWRM A 0 A_jumpIfCloser(25,"Melee");
			AWRM  A 0 A_Jump(75, "ScootAway","ScootAway","GonnaSPITTHEBOIatYou");
			AWRM A 1 A_FaceTarget; 
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 1 bright A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 2 bright A_BigBoyDevilerRandomRunawayNoPainScoot();
			AWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
			AWRM A 0 bright A_BigBoyDevilerThePrettyGoodSpit();
			goto see;
		GonnaSPITTHEBOIatYou:
			AWRM A 0 A_jumpIfCloser(25,"Melee");
			AWRM A 0 A_Jump(75, "ScootAway");
			AWRM A 1 A_FaceTarget; 
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 2 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 1 bright A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 2 bright A_BigBoyDevilerRandomRunawayNoPainScoot();
			AWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
			AWRM A 0 bright A_BigBoyDevilerSpitOutTHEBOI();
			goto see;
		SteamingHotPrep:
			AWRM A 0 A_jumpIfCloser(25,"Melee");
			AWRM A 0 A_Jump(75, "ScootAway");
			AWRM A 1 A_FaceTarget; 
			AWRM A 0 A_jumpIfCloser(25,"Melee");
			AWRM A 0 A_Jump(75, "ScootAway");
			AWRM A 1 A_FaceTarget; 
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 2 bright A_BigBoyDevilerRandomRunawayNoPainScoot();
			AWRM A 1 bright ThrustThingZ (0, 20, 0, 0);
			AWRM A 0 bright A_BigBoyDevilerTheHorribleFireVomit();
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 0 bright A_BigBoyDevilerTheHorribleFireVomit();
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTLeft();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 1 bright A_BigBoyDevilerisSteamingHOTRight();
			AWRM A 0 A_ChangeVelocity(0,0,0,CVF_REPLACE);
			AWRM A 0 bright A_BigBoyDevilerTheHorribleFireVomit();
			goto see;
		MidLeap:
			AWRM A 0 A_SpawnItemEx("ATail1",-17,0,0,0,0,0,0,0,0);
			AWRM B 1;//A_SpawnItem ("Fix");
			AWRM A 0 A_CheckFloor ("Land");
			loop;
		Land:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 1 A_Stop;
			AWRM A 1 A_BigBoyDevilerRandomRunawayNoPainScoot;
			goto See;
		latched:
			AWRM CD 1 A_TryWimpyLatch();
			loop;
    	Melee:
			TNT1 A 0 A_Jump(256,"StandardMelee","GonnaBiteYerHeadOffRound2","NOPERUN","Lunge");
			Goto See;
    	StandardMelee:
			AWRM B 5 A_FaceTarget;
    			AWRM A 1 A_BigBoyDevilerChomp();
			AWRM A 10 A_BigBoyDevilerRandomRunawayScoot;
    			Goto See;
		NOPERUN:
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM B 1 A_BigBoyDevilerRandomRunawayNoPainScoot;
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM B 1 A_BigBoyDevilerRandomRunawayNoPainScoot;
			TNT1 A 0 A_Jump(65,"GonnaSPITatYou","GonnaSPITatYou","GonnaBiteYerHeadOffRound2");
			goto see;
		GonnaBiteYerHeadOffRound2:
				AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
				AWRM A 1 A_BigBoyDevilerRandomForwardHop;
				AWRM AB 3 A_SetAngle(angle+random(-15,15));
				AWRM AB 1 A_TryWimpyLatch();
		postmelee:
				AWRM B 6 A_CustomMeleeAttack(random(1,8),"","","teeth",true);
				AWRM A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,10);} //BURRRRN
				AWRM A 0 setstatelabel("see");
		latched:
				AWRM AB random(1,2);
				AWRM A 0 A_JumpIf(!latchtarget,"pain");
				loop;
		fly:
				AWRM AB 1
					{
					A_TryWimpyLatch();
						if
							(bonmobj||floorz>=pos.z||vel.xy==(0,0))setstatelabel("land");
						else if
							(max(abs(vel.x),abs(vel.y)<3))vel.xy+=(cos(angle),sin(angle))*0.1;
					}
					wait;
		land:
				AWRM ABC 3{vel.xy*=0.8;}
				AWRM C 4{vel.xy=(0,0);}
				AWRM ABC 3 A_HDChase("melee",null);
				AWRM A 0 setstatelabel("see");
				
    	Pain:
			TNT1 A 0 {bShootable=True;}
			TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,30);} //yes punch the VISIBLY BURNING WORM
    		AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM B 1 A_BigBoyDevilerRandomRunawayScoot;
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM B 1 A_BigBoyDevilerRandomRunawayScoot;
    		Goto AfterPain;
		AfterPain:
			TNT1 A 0 {bShootable=True;}
			AWRM A 0 A_SpawnItemEx("ATail1",-5,0,0,0,0,0,0,0,0);
			AWRM B 1;
			TNT1 A 0 A_Jump(256, "ScootRandom", "ScootForward", "HopForward","ScootAway");
        Death:
			//TNT1 A 0 ThrustThing(angle*256/360, 0, 0, 0);
			TWBA ABCB 1;
			TNT1 A 0 A_PlaySound("Worm/Death");
			TWAA ABCBABCBABCBABCB 1;
			DEAD AAAA 1;
			DEAD BBBB 1;
			DEAD C 1;
			
			//DEAD A 0 A_SpawnItem("AJawB",0,0,0);
			DEAD A 0 A_SpawnItemEx("AJawU", 0, 0, 20, 1, 0, 0, Random(0, 360), 0);
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
		raise:
				DEAD CCBBAA 3;
				AWRM CCBBAA 3;
				AWRM A 0 A_Jump(256,"see");
	}
}

class HDBigBoyEggSpit : HDWimpyFireBall
{
	default
		{
			damagetype "hot";
			radius 10;
			height 10;
			speed 32;
			scale 0.3;
			damage (1);
			reactiontime 20;
			gravity 0.15;
			translation "0:17=@24[255,0,0]";
		}
	states
		{
	spawn:
			
			EGGG ABABABAB 1 A_FBTail();
			goto spawn2;
	spawn2:
			EGGG A 0 A_countdown;
			EGGG AB 3 A_HDIBFly();
			loop;
	death:
			TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
			TNT1 A 1{
			A_SpawnItemEx("HDExplosion",0,0,3,
				vel.x,vel.y,vel.z+1,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
			A_NoBlocking();
			}
			TNT1 A 0 A_SpawnItemEx("BabyDeviler",flags:SXF_NOCHECKPOSITION);
			TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,5);}
			goto super::death;
		}
	}

class HDBigBoyFlamer : HDWimpyFireBall
	{ 
	default
		{
	
			missiletype "HDWimpyFireBallTail";
			damagetype "hot";
			speed 24;
			scale 0.5;
			damage (2);
			reactiontime 20;
			gravity 0.15;
		}
	states
			{
	spawn:
			
			ADBS ABABABAB 1 A_FBTail();
			goto spawn2;
	spawn2:
			ADBS A 0 A_countdown;
			ADBS AB 3 A_HDIBFly();
			loop;
	death:
			TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
			TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,3);}
			goto super::death;
		}
	}
	
class BigBoyBlazerShotTail:HDActor{
	default{
		+nointeraction
		+forcexybillboard
		renderstyle "add";
		alpha 0.6;
		scale 0.7;
	}
	states{
	spawn:
		ADBS E 2 bright A_FadeOut(0.2);
		TNT1 A 0 A_StartSound("baron/ballhum",volume:0.4,attenuation:6.);
		loop;
	}
}

class BigBoyBlazerShot:HDActor{
	default{
		+forcexybillboard
		projectile;
		+seekermissile
		damagetype "hot";
		renderstyle "add";
		decal "gooscorch";
		alpha 0.8;
		scale 0.6;
		radius 4;
		height 6;
		speed 16;
		damage 6;
		seesound "baron/attack";
		speed 28;
		scale 0.7;
		damage (10);
		seesound "baron/attack";
		deathsound "imp/shotx";
	}
	int user_counter;
	override void postbeginplay(){
		super.postbeginplay();

		let hdmb=hdmobbase(target);
		if(hdmb)hdmb.firefatigue+=int(HDCONST_MAXFIREFATIGUE*0.1);
	}
	states{
	spawn:
		ADBS EDC 1 bright;
		ADBS ABABA 2 bright;
		ADBS BAB 3 bright;
	spawn2:
		ADBS A 2 bright A_SeekerMissile(5,10);
		ADBS B 2 bright A_SpawnItemEx("BigBoyBlazerShotTail",-3,0,3,3,0,random(1,2),0,161,0);
		ADBS A 2 bright A_SeekerMissile(5,9);
		ADBS B 2 bright A_SpawnItemEx("BigBoyBlazerShotTail",-3,0,3,3,0,random(1,2),0,161,0);
		ADBS A 2 bright A_SeekerMissile(4,8);
		ADBS B 2 bright A_SpawnItemEx("BigBoyBlazerShotTail",-3,0,3,3,0,random(1,2),0,161,0);
		ADBS A 2 bright A_SeekerMissile(3,6);
		ADBS B 2 bright A_SpawnItemEx("BigBoyBlazerShotTail",-3,0,3,3,0,random(1,2),0,161,0);
	spawn3:
		TNT1 A 0 A_JumpIf(user_counter>4,"spawn4");
		TNT1 A 0 {user_counter++;}
		ADBS A 3 bright A_SeekerMissile(1,1);
		ADBS B 3 bright A_SpawnItemEx("BigBoyBlazerShotTail",-3,0,3,3,0,random(1,2),0,161,0);
		loop;
	spawn4:
		ADBS A 3 bright A_SpawnItemEx("BigBoyBlazerShotTail",-3,0,3,3,0,random(1,2),0,161,0);
		TNT1 A 0 A_JumpIf(pos.z-floorz<10,2);
		ADBS B 3 bright A_ChangeVelocity(frandom(-0.2,1),frandom(-1,1),frandom(-1,0.9),CVF_RELATIVE);
		loop;
		ADBS B 3 bright A_ChangeVelocity(frandom(-0.2,1),frandom(-1,1),frandom(-0.6,1.9),CVF_RELATIVE);
		loop;
	death:
		TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,3);}
		ADBS CDE 4 bright A_FadeOut(0.2);
		stop;
	}
}

Class ATail1 : Actor
{
	Default
	{
  Scale 0.75;
  +NOGRAVITY;
  translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
  }
  States
  {
  Spawn:
    ATAI A 5;
    Goto Death;
  Death:
	TNT1 A 0 A_SpawnItemEx("ATail2",0,0,0,0,0,0,0,0,0);
	Stop;
  }
}

Class ATail2 : Actor
{
	Default
	{
  Scale 0.7;
  +NOGRAVITY;
  translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
	}
 States
  {
  Spawn:
    ATAI A 5;
    Goto Death;
  Death:
	TNT1 A 0 A_SpawnItemEx("ATail3",0,0,0,0,0,0,0,0,0);
	Stop;
  }
}

Class ATail3 : Actor
{
	Default
	{
  Scale 0.65;
  +NOGRAVITY;
	translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
	}
  States
  {
  Spawn:
    ATAI A 5;
	Stop;
  }
}
//Guts


Class AJawU : Actor
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
	Scale 0.6;
	translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
	}
    States
    {
    Spawn:
		JAWA A 0 A_SetGravity (0.2);
        JAWA A 0 ThrustThingZ (0, 20, 0, 1);
        goto See ;
    See:
        JAWA ABCDEFGH 3;
        loop;
    Death:
        JAWA A 1 A_SpawnItem("AJawLand",0,0,0);
        Stop;
    }
}
Class AJawLand : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.6;
	translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
	}
    States
    {
    Spawn:
		JAAL A 1;
		TNT1 A 0 A_PlaySound("Worm/Splat");
        goto Splat;
	Splat:
		JAAL A 1;
        loop;
    }
}

Class AJawB : Actor
{
	Default
	{
    -NOBLOCKMAP;
    Radius 2;
	Scale 0.6;
	translation "13:15=212:216", "0:3=165:167", "155:155=181:181", "80:111=171:191", "5:12=167:167", "236:239=216:223", "128:151=48:63", "64:79=208:223";
	}
    States
    {
    Spawn:
        JAWZ A 1;
        goto Spawn;
    }
}

