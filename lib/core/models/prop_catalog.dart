enum PropCategory {
  ipscTargets('МИШЕНИ IPSC'),
  steel('МЕТАЛЛИЧЕСКИЕ МИШЕНИ'),
  movers('ДВИЖУЩИЕСЯ И АКТИВАТОРЫ'),
  visualBarriers('ВИЗУАЛЬНЫЕ БАРЬЕРЫ'),
  barricades('БАРРИКАДЫ'),
  doorsPorts('ДВЕРИ И ОКНА'),
  markers('МАРКЕРЫ СТЕЙДЖА'),
  support('ОПОРНЫЕ КОНСТРУКЦИИ');

  const PropCategory(this.label);

  final String label;
}

enum PropArchetype { billboard, floorDisc, floorLine }
