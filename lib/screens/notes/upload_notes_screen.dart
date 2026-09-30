import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notes_service.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  String selectedSubject = 'ICT';
  String fileName = '';
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Upload Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter note title',
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Subject',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(
                  hintText: 'Select Subject',
                ),
                items: const [
                  DropdownMenuItem(value: 'ICT', child: Text('ICT')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                  DropdownMenuItem(value: 'Science', child: Text('Science')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedSubject = val);
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Upload File',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              // Choose File Box matching Figma iPhone 16 & 17 Pro Max - 18
              GestureDetector(
                onTap: () {
                  setState(() {
                    fileName = "Communication_Networks_Lecture1.pdf";
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        fileName.isEmpty ? 'Choose File' : fileName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'supported formats: PDF, DOC, DOCX',
                        style: TextStyle(color: AppColors.textLight, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write description...',
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('0/500', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: submitting ? null : () async {
                  final title = titleController.text.trim();
                  final description = descriptionController.text.trim();
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final navigator = Navigator.of(context);

                  if (title.isEmpty) {
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('Please enter a note title.')),
                    );
                    return;
                  }

                  setState(() => submitting = true);
                  try {
                    await NotesService.addNote(
                      title: title,
                      subject: selectedSubject,
                      description: description,
                      fileType: fileName.isEmpty ? 'PDF' : fileName.split('.').last,
                    );
                    if (!mounted) return;
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('Note uploaded successfully!')),
                    );
                    navigator.pop();
                  } catch (error) {
                    if (!mounted) return;
                    messenger?.showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  } finally {
                    if (mounted) setState(() => submitting = false);
                  }
                },
                child: Text(submitting ? 'Uploading...' : 'Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
