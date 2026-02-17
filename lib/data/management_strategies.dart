// Management Strategies data for each coconut pest.
// Source: Nature Damage of Coconut Pests – PDF (PCA Reference)

class ManagementStrategy {
  final String category; // e.g., 'Cultural Control'
  final String icon;
  final List<String> strategies;

  const ManagementStrategy({
    required this.category,
    required this.icon,
    required this.strategies,
  });
}

class PestManagementInfo {
  final String pestName;
  final String scientificName;
  final String referencePages;
  final List<ManagementStrategy> strategies;

  const PestManagementInfo({
    required this.pestName,
    required this.scientificName,
    required this.referencePages,
    required this.strategies,
  });
}

/// All management strategies indexed by pest key
const Map<String, PestManagementInfo> managementStrategiesData = {
  'Rhinoceros Beetle': PestManagementInfo(
    pestName: 'Oryctes rhinoceros (Rhinoceros Beetle)',
    scientificName: 'Oryctes rhinoceros',
    referencePages: 'Pages 3–23',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Maintain strict farm sanitation by removing decomposing organic matter such as rotting logs, manure heaps, and decaying plant residues that serve as breeding sites.',
          'Practice intercropping and cover cropping to reduce exposed breeding areas.',
          'Apply proper fertilization to help palms recover from crown damage and improve tolerance.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Manually extract adult beetles from the crown, especially in young palms.',
          'Apply coal tar or similar protective materials on wounds to prevent further beetle entry.',
          'Use log traps placed around the farm to attract and destroy adult beetles.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Apply green muscardine fungus (Metarhizium anisopliae) in breeding sites.',
          'Use Oryctes nudivirus (OrNV) through infected beetle release or treated traps to suppress populations.',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Use systemic insecticide trunk or frond injection when infestation is severe.',
          'Conduct soil drenching or root infusion where recommended.',
          'Deploy aggregation pheromone traps as part of mass trapping programs.',
        ],
      ),
    ],
  ),

  'Brontispa': PestManagementInfo(
    pestName: 'Brontispa longissima (Coconut Leaf Beetle)',
    scientificName: 'Brontispa longissima',
    referencePages: 'Pages 28–37',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Remove and destroy infested spear leaves immediately to stop population buildup.',
          'Ensure proper fertilization to promote faster recovery and leaf regeneration.',
          'Observe quarantine measures to prevent spread between farms.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Manually cut and dispose of heavily infested folded leaves.',
          'Avoid leaving removed leaves in the plantation to prevent reinfestation.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Release parasitoid wasp (Tetrastichus brontispae), a primary biological control agent.',
          'Encourage predators such as earwig (Chelisoches morio).',
          'Spray entomopathogenic fungi (Beauveria bassiana or Metarhizium anisopliae) directly on the spear leaf only until drip.',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Chemical use is generally discouraged in favor of biological control.',
          'Consult PCA for approved chemical treatments if biological control is insufficient.',
        ],
      ),
    ],
  ),

  'Brontispa Pupa': PestManagementInfo(
    pestName: 'Brontispa longissima (Coconut Leaf Beetle)',
    scientificName: 'Brontispa longissima',
    referencePages: 'Pages 28–37',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Remove and destroy infested spear leaves immediately to stop population buildup.',
          'Ensure proper fertilization to promote faster recovery and leaf regeneration.',
          'Observe quarantine measures to prevent spread between farms.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Manually cut and dispose of heavily infested folded leaves.',
          'Avoid leaving removed leaves in the plantation to prevent reinfestation.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Release parasitoid wasp (Tetrastichus brontispae), a primary biological control agent.',
          'Encourage predators such as earwig (Chelisoches morio).',
          'Spray entomopathogenic fungi (Beauveria bassiana or Metarhizium anisopliae) directly on the spear leaf only until drip.',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Chemical use is generally discouraged in favor of biological control.',
          'Consult PCA for approved chemical treatments if biological control is insufficient.',
        ],
      ),
    ],
  ),

  'APW': PestManagementInfo(
    pestName: 'Asiatic Palm Weevil (APW)',
    scientificName: 'Rhynchophorus ferrugineus',
    referencePages: 'Pages 96–110',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Practice strict sanitation by removing and destroying severely infested palms.',
          'Avoid trunk injuries during harvesting, pruning, or farm operations.',
          'Apply preventive trunk spraying to discourage egg laying.',
          'Enforce quarantine regulations to prevent pest spread.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Conduct regular surveillance for holes, frass, fermented odor, and gnawing sounds.',
          'Cut and destroy palms with extensive internal damage.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Apply entomopathogenic fungus (Beauveria bassiana).',
          'Use nematode (Praecocilenchus ferruginophorus) against larvae.',
          'Utilize natural enemies such as Pseudomonas aeruginosa, predatory mites (Hypoaspis spp.), and earwigs (Chelisoches morio).',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Apply the Drill–Pour–Plug Method: Drill holes into the trunk, pour insecticide solution, then seal holes to retain chemical.',
          'Consult PCA for exact insecticide name, dosage, and pre-harvest interval (PHI).',
        ],
      ),
    ],
  ),

  'APW Adult': PestManagementInfo(
    pestName: 'Asiatic Palm Weevil (APW)',
    scientificName: 'Rhynchophorus ferrugineus',
    referencePages: 'Pages 96–110',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Practice strict sanitation by removing and destroying severely infested palms.',
          'Avoid trunk injuries during harvesting, pruning, or farm operations.',
          'Apply preventive trunk spraying to discourage egg laying.',
          'Enforce quarantine regulations to prevent pest spread.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Conduct regular surveillance for holes, frass, fermented odor, and gnawing sounds.',
          'Cut and destroy palms with extensive internal damage.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Apply entomopathogenic fungus (Beauveria bassiana).',
          'Use nematode (Praecocilenchus ferruginophorus) against larvae.',
          'Utilize natural enemies such as Pseudomonas aeruginosa, predatory mites (Hypoaspis spp.), and earwigs (Chelisoches morio).',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Apply the Drill–Pour–Plug Method: Drill holes into the trunk, pour insecticide solution, then seal holes to retain chemical.',
          'Consult PCA for exact insecticide name, dosage, and pre-harvest interval (PHI).',
        ],
      ),
    ],
  ),

  'APW Larvae': PestManagementInfo(
    pestName: 'Asiatic Palm Weevil (APW)',
    scientificName: 'Rhynchophorus ferrugineus',
    referencePages: 'Pages 96–110',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Practice strict sanitation by removing and destroying severely infested palms.',
          'Avoid trunk injuries during harvesting, pruning, or farm operations.',
          'Apply preventive trunk spraying to discourage egg laying.',
          'Enforce quarantine regulations to prevent pest spread.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Conduct regular surveillance for holes, frass, fermented odor, and gnawing sounds.',
          'Cut and destroy palms with extensive internal damage.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Apply entomopathogenic fungus (Beauveria bassiana).',
          'Use nematode (Praecocilenchus ferruginophorus) against larvae.',
          'Utilize natural enemies such as Pseudomonas aeruginosa, predatory mites (Hypoaspis spp.), and earwigs (Chelisoches morio).',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Apply the Drill–Pour–Plug Method: Drill holes into the trunk, pour insecticide solution, then seal holes to retain chemical.',
          'Consult PCA for exact insecticide name, dosage, and pre-harvest interval (PHI).',
        ],
      ),
    ],
  ),

  'Slug Caterpillar': PestManagementInfo(
    pestName: 'Slug Caterpillar',
    scientificName: 'Parasa lepida',
    referencePages: 'Pages 123–129',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Conduct leaf pruning following PCA-recommended procedures only to reduce larval population.',
          'Focus on young palms and seedlings where damage is more severe.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Collect and destroy pupal cocoons found on leaves or trunks.',
          'Use light traps to attract and kill adult moths.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Release hymenopterous parasitoids.',
          'Apply fungal pathogens and nuclear polyhedrosis virus (NPV).',
          'Spray virus-water suspension prepared from virus-infected larvae, especially on seedlings.',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Consult PCA for approved chemical treatments when biological control is insufficient.',
          'Chemical information not specified in the reference document.',
        ],
      ),
    ],
  ),

  'White Grub': PestManagementInfo(
    pestName: 'White Grub',
    scientificName: 'Leucopholis irrorata',
    referencePages: '',
    strategies: [
      ManagementStrategy(
        category: 'Cultural Control',
        icon: '🌱',
        strategies: [
          'Remove decaying organic materials around the plantation.',
          'Practice crop rotation and proper land preparation.',
        ],
      ),
      ManagementStrategy(
        category: 'Mechanical / Physical Control',
        icon: '🔧',
        strategies: [
          'Hand-collect grubs during land preparation.',
          'Use light traps to capture adult beetles.',
        ],
      ),
      ManagementStrategy(
        category: 'Biological Control',
        icon: '🦠',
        strategies: [
          'Apply entomopathogenic fungi (Metarhizium anisopliae) to soil.',
          'Use entomopathogenic nematodes for soil treatment.',
        ],
      ),
      ManagementStrategy(
        category: 'Chemical Control',
        icon: '⚗️',
        strategies: [
          'Apply soil-applied insecticides as recommended by PCA.',
          'Conduct soil drenching around affected root zones.',
        ],
      ),
    ],
  ),
};

/// Get management info for a pest, with fuzzy matching
PestManagementInfo? getManagementInfo(String pestName) {
  // Direct match
  if (managementStrategiesData.containsKey(pestName)) {
    return managementStrategiesData[pestName];
  }

  // Fuzzy match
  final lower = pestName.toLowerCase();
  for (final entry in managementStrategiesData.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
    if (lower.contains(entry.key.toLowerCase()) ||
        entry.key.toLowerCase().contains(lower)) {
      return entry.value;
    }
  }

  // Match by common names
  if (lower.contains('rhinoceros') || lower.contains('oryctes')) {
    return managementStrategiesData['Rhinoceros Beetle'];
  }
  if (lower.contains('brontispa') || lower.contains('leaf beetle')) {
    return managementStrategiesData['Brontispa'];
  }
  if (lower.contains('apw') ||
      lower.contains('weevil') ||
      lower.contains('rhynchophorus')) {
    return managementStrategiesData['APW'];
  }
  if (lower.contains('slug') ||
      lower.contains('caterpillar') ||
      lower.contains('parasa')) {
    return managementStrategiesData['Slug Caterpillar'];
  }
  if (lower.contains('grub') || lower.contains('leucopholis')) {
    return managementStrategiesData['White Grub'];
  }

  return null;
}
