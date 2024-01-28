
import 'package:google_maps_webservice/places.dart';

class PlacesService {
  final placesApiClient = GoogleMapsPlaces(apiKey: 'Apikey');

  Future<List<Prediction>> getAutocompleteResults(String input) async {
    final response = await placesApiClient.autocomplete(
      input,
      components: [Component(Component.country, 'IN')], // Restrict to India
    );

    if (response.isOkay) {
      return response.predictions;
    } else {
      throw Exception('Error fetching autocomplete results');
    }
  }

  Future<Map<String, String>> getPlaceDetails(String placeId) async {
    final List<String> fields = ['id', 'name', 'geometry'];
    final response = await placesApiClient.getDetailsByPlaceId(
      placeId,
      fields: fields,
    );

    if (response.isOkay) {
      final Map<String, String> placeDetails = {
        'id': response.result.placeId ?? '', // Default to an empty string if null
        'name': response.result.name ?? '', // Default to an empty string if null
      };

      // Check if geometry and location are not null before accessing
      if (response.result.geometry?.location != null) {
        placeDetails['latitude'] = response.result.geometry?.location.lat.toString() ?? '';
        placeDetails['longitude'] = response.result.geometry?.location.lng.toString() ?? '';
      } else {
        // Handle the case where location information is not available
        placeDetails['latitude'] = '';
        placeDetails['longitude'] = '';
      }

      return placeDetails;
    } else {
      throw Exception('Error fetching place details');
    }
  }



}
