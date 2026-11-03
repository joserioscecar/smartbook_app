extension StringNormalizationExtension on String {
  String normalizar() {
    var resultado = trim().toLowerCase();
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    for (final entrada in acentos.entries) {
      resultado = resultado.replaceAll(entrada.key, entrada.value);
    }
    return resultado;
  }
}
