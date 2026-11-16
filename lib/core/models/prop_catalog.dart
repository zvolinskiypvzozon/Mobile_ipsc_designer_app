enum PropCategory {
  ipscTargets('МИШЕНИ IPSC'),
  steel('СТАЛЬНЫЕ МИШЕНИ'),
  movers('ДВИЖУЩИЕСЯ И АКТИВАТОРЫ'),
  hardCoverVision('ХАРД-КАВЕР И ВИЗИОН'),
  barricades('БАРРИКАДЫ'),
  doorsPorts('ДВЕРИ И ПОРТЫ'),
  markers('МАРКЕРЫ СТЕЙДЖА'),
  support('ОПОРНЫЕ КОНСТРУКЦИИ');

  const PropCategory(this.label);

  final String label;
}

enum PropArchetype { billboard, floorDisc, floorLine }
