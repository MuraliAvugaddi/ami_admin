import 'package:ami_admin/controllers/SpecialFoodController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSpecialFoodManager extends StatelessWidget {
  AdminSpecialFoodManager({super.key});
  final controller = Get.put(AdminSpecialController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(title: Text("Menu Manager", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xffFFC800), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        label: const Text("Add New Item"),
        icon: const Icon(Icons.fastfood),
        backgroundColor: Colors.black,
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.specialItems.length,
          itemBuilder: (context, index) {
            final item = controller.specialItems[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover, 
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                ),
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("₹${item['price']}"),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => controller.deleteItem(item['_id'])),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nCtrl = TextEditingController();
    final pCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Upload New Item",
      content: GetBuilder<AdminSpecialController>(builder: (ctrl) {
        return Column(
          children: [
            // IMAGE PICKER SECTION
            InkWell(
              onTap: () => ctrl.pickImage(),
              child: Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
                child: ctrl.pickedImage != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(ctrl.pickedImage!, fit: BoxFit.cover))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text("Tap to select image")]),
              ),
            ),
            const SizedBox(height: 15),
            TextField(controller: nCtrl, decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: pCtrl, decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ctrl.addNewItem(nCtrl.text, double.parse(pCtrl.text)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
              child: const Text("SEND TO USER APP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }
}