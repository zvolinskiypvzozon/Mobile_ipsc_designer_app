enum PropCategory {
  ipscTargets('МИШЕНИ IPSC'),
  steel('МЕТАЛЛИЧЕСКИЕ МИШЕНИ'),
  movers('ДВИЖУЩИЕСЯ И АКТИВАТОРЫ'),
  visualBarriers('ДЕКОРАЦИИ'),
  doorsPorts('ДВЕРИ И ОКНА'),
  markers('МАРКЕРЫ СТЕЙДЖА');

  const PropCategory(this.label);

  final String label;
}

enum PropArchetype { billboard, floorDisc, floorLine }
