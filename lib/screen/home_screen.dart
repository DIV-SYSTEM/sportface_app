import 'package:flutter/material.dart';
import '../data/companion_data.dart';
import '../widgets/companion_card.dart';
import '../model/companion_model.dart';
import 'create_requirement_form.dart';
import 'view_groups_screen.dart';

class HomeScreen extends StatefulWidget {
  final String initialUser;

  const HomeScreen({super.key, required this.initialUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCity;
  String? selectedSport;
  String? selectedGender;
  String? selectedAgeLimit;
  String? selectedPaidStatus;
  String? selectedFood;
  String? selectedTravel;
  DateTime? selectedDate;
  late String currentUser;

  List<CompanionModel> filteredData = companionData;

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

  void _applyFilter() {
    setState(() {
      filteredData = companionData.where((item) {
        final matchesCity = selectedCity == null || item.city == selectedCity;
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
        final matchesFood =
            selectedFood == null || item.food == selectedFood;
        final matchesTravel =
            selectedTravel == null || item.travel == selectedTravel;

        return matchesCity &&
            matchesSport &&
            matchesDate &&
            matchesGender &&
            matchesAge &&
            matchesPaid &&
            matchesFood &&
            matchesTravel;
      }).toList();
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
      selectedFood = null;
      selectedTravel = null;
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.arrow_drop_down), // Explicitly set dropdown icon
        iconSize: 24,
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
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                _buildDropdown("Food", selectedFood, ["Included", "Not Included"], (val) => setState(() => selectedFood = val)),
                _buildDropdown("Travel", selectedTravel, ["Own Vehicle", "Transport", "Shared Cab"], (val) => setState(() => selectedTravel = val)),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Date",
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onTap: _pickDate,
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