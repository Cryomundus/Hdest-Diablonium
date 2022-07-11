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
			case 'FlyingSkull':
				if (random[monchancerand]() <= 45)
				{
					e.Replacement = 'WretchedGhoul';
				}
				break;
			case 'SpectreSpawner':
				if (random[monchancerand]() <= 45)
				{
					e.Replacement = 'WretchedGhoul';
				}
				break;	
			case'BabuSpectreSpawner':
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
					if (random[monchancerand]() <= 80)
						{
							e.Replacement = 'TeenDeviler';
							break;
						}
					
					e.Replacement = 'ImpSpawner';
					break;
		case'PainBringer':
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
