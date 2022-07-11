//

class HDestDiabloniumSpawner : EventHandler
{
	override void CheckReplacement(ReplaceEvent e)
	{
		if (!e.Replacement)
		{
			return;
		}
		
		switch (e.Replacement.GetClassName())
		{
			//wretched
			case 'FlyingSkull':
				if (random[monchancerand]() <= 45)
				{
					e.Replacement = 'WretchedGhoul';
				}
				//e.Replacement = 'FlyingSkull';
				break;
			case 'SpectreSpawner':
				if (random[monchancerand]() <= 45)
				{
					e.Replacement = 'WretchedGhoul';
				}
				//e.Replacement = 'FlyingSkull';
				break;	
			// baby deviler	
			case'BabuSpectreSpawner':
				//'BabuSpectreSpawner':
					if (random[BabDevrand]() <= 115)
						{
							if (random[monchancerand]() <= 70)
							{
							e.Replacement = 'BabyDeviler';
							e.Replacement = 'BabyDeviler';
							e.Replacement = 'BabyDeviler';
							break;
							}
							else
							{
							e.Replacement = 'BabyDeviler';
							break;
							}
						}
					
					e.Replacement = 'BabuSpectreSpawner';
					break;
				case'ImpSpawner':
				//'BabuSpectreSpawner':
					if (random[monchancerand]() <= 80)
						{
							e.Replacement = 'TeenDeviler';
							break;
						}
					
					e.Replacement = 'ImpSpawner';
					break;
		case'PainBringer':
				//'BabuSpectreSpawner':
					if (random[monchancerand]() <= 80)
						{
							e.Replacement = 'AdultDeviler';
							break;
						}
					
					e.Replacement = 'PainBringer';
					break;
		}
	}
}
