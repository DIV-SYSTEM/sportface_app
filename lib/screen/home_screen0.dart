import 'package:flutter/material.dart';
import '../data/companion_data.dart';
import '../widgets/companion_card.dart';
import '../model/companion_model.dart';
import 'create_requirement_form.dart';
import 'view_groups_screen.dart';
import '../services/location_filter_service.dart';

class Home_Sport extends StatefulWidget {
  final String initialUser;

  const Home_Sport({super.key, required this.initialUser});

  @override
  State<Home_Sport> createState() => _Home_SportState();
}

class _Home_SportState extends State<Home_Sport> {
  String? selectedCity;
  String? selectedSport;
  String? selectedGender;
  String? selectedAgeLimit;
  String? selectedPaidStatus;
  DateTime? selectedDate;
  double distanceFilterKm = 0;
  late String currentUser;

  List<CompanionModel> filteredData = companionData;
  final LocationFilterService _locationService = LocationFilterService();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController newUserController = TextEditingController();

  final List<String> allCities = {
    ...companionData.map((e) => e.city),
  }.toList();

  @override
  void initState() {
    super.initState();
    currentUser = widget.initialUser;
    print("HomeScreen: Initialized with currentUser = $currentUser");
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _applyFilter() async {
    setState(() {
      filteredData = companionData; // Reset to all data initially
    });

    // Apply distance filter
    final distanceFilteredData = await _locationService.filterByDistance(distanceFilterKm);

    setState(() {
      filteredData = distanceFilteredData.where((item) {
        final matchesCity =
            distanceFilterKm == 0 ? (selectedCity == null || item.city == selectedCity) : true;
        final matchesSport =
            selectedSport == null || item.sportName == selectedSport;
        final matchesDate =
            selectedDate == null || item.date == dateController.text;
        final matchesGender =
            selectedGender == null || item.gender == selectedGender;
        final matchesAge =
            selectedAgeLimit == null || item.ageLimit == selectedAgeLimit;
        final matchesPaid =
            selectedPaidStatus == null || item.paidStatus == selectedPaidStatus;

        return matchesCity &&
            matchesSport &&
            matchesDate &&
            matchesGender &&
            matchesAge &&
            matchesPaid;
      }).toList();

      if (distanceFilterKm > 0) {
        final userLocation = _locationService.getUserLocation();
        userLocation.then((location) {
          if (location == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied. Showing all results.")),
            );
          }
        });
      }
    });
  }

  void _resetFilter() {
    setState(() {
      selectedCity = null;
      selectedSport = null;
      selectedDate = null;
      selectedGender = null;
      selectedAgeLimit = null;
      selectedPaidStatus = null;
      distanceFilterKm = 0;
      dateController.clear();
      filteredData = companionData;
    });
  }

  void _resetData() {
    setState(() {
      companionData.clear();
      groupData.clear();
      pendingRequests.clear();
      groupMessages.clear();
      availableUsers.clear();
      availableUsers.addAll(["Demo User", "Sneha Roy", "Rahul Verma"]);
      currentUser = "Demo User";
      filteredData = companionData;
      print("Cleared all data, reset users: $availableUsers");
      logGroupData("After reset");
    });
  }

  void _createUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New User"),
        content: TextField(
          controller: newUserController,
          decoration: const InputDecoration(
            labelText: "User Name",
            hintText: "e.g., Amit Sharma",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newUser = newUserController.text.trim();
              if (newUser.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User name cannot be empty")),
                );
                return;
              }
              if (availableUsers
                  .any((user) => user.toLowerCase() == newUser.toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User name already exists")),
                );
                return;
              }
              setState(() {
                availableUsers.add(newUser);
                currentUser = newUser;
                newUserController.clear();
                print("Created user: $newUser, currentUser: $currentUser");
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User $newUser created!")),
              );
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _switchUser(String? newUser) {
    if (newUser != null) {
      setState(() {
        currentUser = newUser;
        print("Switched to user: $currentUser");
      });
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> options,
      Function(String?) onChanged) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value,
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Sport Companions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _createUser,
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text("Create User"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: currentUser,
                    items: availableUsers.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Text(user, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: _switchUser,
                    isDense: true,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "User",
                      prefixIcon: const Icon(Icons.person, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateRequirementForm(
                            currentUser: currentUser,
                            onCreate: (CompanionModel newCompanion, GroupModel newGroup) {
                              setState(() {
                                companionData.add(newCompanion);
                                groupData.add(newGroup);
                                filteredData = companionData;
                                print("Added to groupData: ${newGroup.groupId}, Name: ${newGroup.groupName}, Organiser: ${newGroup.organiserName}");
                                logGroupData("After adding group in home");
                              });
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Create Requirement"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewGroupsScreen(
                            key: UniqueKey(),
                            currentUser: currentUser,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.group),
                    label: const Text("View Group"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _resetData,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset Data"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDropdown("City", selectedCity, allCities, (val) => setState(() => selectedCity = val)),
                _buildDropdown("Sport", selectedSport, ["Football", "Cricket", "Badminton", "Chess", "Carrom", "PUBG"], (val) => setState(() => selectedSport = val)),
                _buildDropdown("Gender", selectedGender, ["All", "Male", "Female"], (val) => setState(() => selectedGender = val)),
                _buildDropdown("Age Limit", selectedAgeLimit, ["18-25", "26-33", "34-40", "40+"], (val) => setState(() => selectedAgeLimit = val)),
                _buildDropdown("Type", selectedPaidStatus, ["Paid", "Unpaid"], (val) => setState(() => selectedPaidStatus = val)),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Date",
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: _pickDate,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Distance: ${distanceFilterKm.toStringAsFixed(0)} km",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Slider(
                        value: distanceFilterKm,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: "${distanceFilterKm.toStringAsFixed(0)} km",
                        onChanged: (value) {
                          setState(() {
                            distanceFilterKm = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    child: const Text("Apply Filter"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetFilter,
                    child: const Text("Reset Filter"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (filteredData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("No companions match your filters."),
                ),
              )
            else
              ListView.builder(
                itemCount: filteredData.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final companion = filteredData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: CompanionCard(
                      data: companion,
                      currentUser: currentUser,
                      onReadMorePressed: () {},
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
