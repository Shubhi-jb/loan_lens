enum FairnessLevel { safe, warning, danger }

class Finding {
  final String term;
  final String description;
  final FairnessLevel level;

  Finding({
    required this.term,
    required this.description,
    required this.level,
  });
}
