enum PropCategory {
  paperTargets('Paper targets'),
  steel('Steel & plates'),
  movers('Movers & activators'),
  hardCoverVision('Hard cover & vision'),
  barricades('Barricades'),
  doorsPorts('Doors & ports'),
  markers('Stage markers'),
  support('Support structures');

  const PropCategory(this.label);

  final String label;
}

enum PropArchetype { billboard, floorDisc, floorLine }
