import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/location_service.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/providers/add_story_provider.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/providers/location_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/screens/add_story_screen.dart';

/// Step 3: Add (or detect) a location
class AddLocationStep extends ConsumerStatefulWidget {
  const AddLocationStep({Key? key}) : super(key: key);

  @override
  ConsumerState<AddLocationStep> createState() => _AddLocationStepState();
}

class _AddLocationStepState extends ConsumerState<AddLocationStep> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    // Start detecting current location when the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectCurrentLocation();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _showSearchResults = true;
      });

      // Debounce search requests
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text ==
            ref.read(locationSearchProvider).searchQuery) {
          return;
        }
        ref
            .read(locationSearchProvider.notifier)
            .searchLocations(_searchController.text);
      });
    } else {
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  Future<void> _detectCurrentLocation() async {
    await ref.read(locationSearchProvider.notifier).detectCurrentLocation();
    final locationState = ref.read(locationSearchProvider);

    if (locationState.detectedLocation != null) {
      // Update the StoryData with the detected location
      ref.read(storyProvider.notifier).setLocationData(
            locationState.detectedLocation!.locationLabel,
            locationState.detectedLocation!.latitude,
            locationState.detectedLocation!.longitude,
          );

      // Update the search controller text
      _searchController.text = locationState.detectedLocation!.locationLabel;
    }
  }

  void _selectLocation(LocationResult location) {
    ref.read(locationSearchProvider.notifier).selectLocation(location);

    // Update the StoryData with the selected location
    ref.read(storyProvider.notifier).setLocationData(
          location.locationLabel,
          location.latitude,
          location.longitude,
        );

    // Update the search controller text and close the search results
    _searchController.text = location.locationLabel;
    _searchFocusNode.unfocus();
    setState(() {
      _showSearchResults = false;
    });
  }

  void _clearLocation() {
    ref.read(locationSearchProvider.notifier).clearSelectedLocation();
    ref.read(storyProvider.notifier).setLocationData('', null, null);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationSearchProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Image.asset(
              "assets/images/location.png",
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              if (locationState.isDetectingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Search input with suffix icon for clearing
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColor.colorABB0B9),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: "Search for a location",
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColor.color0C1024,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearLocation,
                      )
                    : null,
              ),
            ),
          ),

          // Location search error
          if (locationState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                locationState.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // Search results
          if (_showSearchResults)
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(top: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: locationState.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : locationState.searchResults.isEmpty
                        ? const ListTile(
                            title: Text('No results found'),
                            leading: Icon(Icons.info_outline),
                          )
                        : ListView.builder(
                            itemCount: locationState.searchResults.length,
                            itemBuilder: (context, index) {
                              final location =
                                  locationState.searchResults[index];
                              return ListTile(
                                title: Text(location.locationLabel),
                                subtitle: Text(
                                  location.rawData['display_name'] ??
                                      '${location.latitude}, ${location.longitude}',
                                ),
                                leading: const Icon(Icons.location_on),
                                onTap: () => _selectLocation(location),
                              );
                            },
                          ),
              ),
            ),

          if (!_showSearchResults)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: RichText(
                text: TextSpan(
                  text: locationState.detectedLocation != null
                      ? "Your location has been detected automatically. Click "
                      : "Please search for your location or click ",
                  style: const TextStyle(
                    color: Color(0xFF5D6778),
                    fontSize: 16,
                    height: 1.9,
                  ),
                  children: [
                    TextSpan(
                      text: locationState.detectedLocation != null
                          ? "\"Confirm\""
                          : "\"Detect Location\"",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.9,
                      ),
                    ),
                    TextSpan(
                      text: locationState.detectedLocation != null
                          ? " to confirm your location or update it to reflect where your story took place."
                          : " to try detecting your current location.",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D6778),
                        height: 1.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_showSearchResults && locationState.detectedLocation == null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: AppButton(
                text: "Detect Location",
                onPressed: locationState.isDetectingLocation
                    ? () {}
                    : _detectCurrentLocation,
                buttonType: ButtonType.secondary,
                borderRadius: 32,
                isIconLeft: true,
                icon: Icon(
                  Icons.my_location,
                  color: AppColor.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
