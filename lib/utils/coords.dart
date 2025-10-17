// Small helper to read latitude/longitude from Firestore documents
double? getLat(Map<String, dynamic>? doc) {
  if (doc == null) return null;
  if (doc.containsKey('userLat') && doc['userLat'] != null){
    return (doc['userLat'] as num).toDouble();
  }else {
    if (doc.containsKey('latitude') && doc['latitude'] != null)
    return (doc['latitude'] as num).toDouble();
  }
  return null;
}

double? getLng(Map<String, dynamic>? doc) {
  if (doc == null) return null;
  if (doc.containsKey('userLng') && doc['userLng'] != null)
    return (doc['userLng'] as num).toDouble();
  if (doc.containsKey('longitude') && doc['longitude'] != null)
    return (doc['longitude'] as num).toDouble();
  return null;
}
