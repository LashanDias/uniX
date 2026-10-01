import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:ui' as ui;
import '../../services/marketplace_service.dart';
import '../../core/constants/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  String category = 'Books';
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  XFile? productImage;
  bool posting = false;

  Future<void> _postProduct() async {
    final title = titleController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    if (title.isEmpty ||
        title.length > 200 ||
        price == null ||
        !price.isFinite ||
        price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a title (up to 200 characters) and a valid price.',
          ),
        ),
      );
      return;
    }
    setState(() => posting = true);
    Reference? uploadedImage;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please sign in to post an item.');
      String imageUrl = '';
      if (productImage != null) {
        final bytes = await productImage!.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          throw StateError('Choose an image smaller than 5 MB.');
        }
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 800);
        try {
          final frame = await codec.getNextFrame();
          try {
            final data = await frame.image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (data == null) throw StateError('Unable to read this image.');
            final ref = FirebaseStorage.instance.ref(
              'products/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.png',
            );
            await ref.putData(
              data.buffer.asUint8List(),
              SettableMetadata(contentType: 'image/png'),
            );
            uploadedImage = ref;
            imageUrl = await ref.getDownloadURL();
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }
      await MarketplaceService.post(
        title: title,
        category: category,
        price: price,
        description: descriptionController.text.trim(),
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product posted successfully!')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (uploadedImage != null) {
        try {
          await uploadedImage.delete();
        } catch (_) {
          /* Keep the original posting error. */
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Unable to post your item. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => posting = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickProductImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => productImage = picked);
    } catch (error) {
      // Naming the failure matters: a blocked file dialog, a denied gallery
      // permission and a plugin that is not registered on this platform all
      // produced the same unhelpful line before.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open the image picker ($error). '
              'On a browser, allow this site to open files.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              const Text(
                'Title',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter Product title',
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Category',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(hintText: 'Select Category'),
                items: const [
                  DropdownMenuItem(value: 'Books', child: Text('Books')),
                  DropdownMenuItem(
                    value: 'Electronics',
                    child: Text('Electronics'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => category = val);
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Price (Rs.)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Enter price'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Images',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickProductImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.inputBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: productImage == null
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: AppColors.textLight),
                              SizedBox(width: 4),
                              Text(
                                'Add Images',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : FutureBuilder(
                            future: productImage!.readAsBytes(),
                            builder: (context, snapshot) => snapshot.hasData
                                ? Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write description....',
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: posting ? null : _postProduct,
                child: Text(posting ? 'Posting...' : 'Post Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
