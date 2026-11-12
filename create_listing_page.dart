import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final contactController = TextEditingController();

  String category = 'jobs';
  String country = 'MK';
  String contactMethod = 'in_app';
  bool saving = false;

  final countries = const {
    'MK': 'North Macedonia',
    'RS': 'Serbia',
    'BA': 'Bosnia and Herzegovina',
    'HR': 'Croatia',
    'AL': 'Albania',
    'ME': 'Montenegro',
    'SI': 'Slovenia',
    'BG': 'Bulgaria',
    'GR': 'Greece',
    'XK': 'Kosovo',
    'RO': 'Romania',
    'CZ': 'Czechia',
    'DE': 'Germany',
    'AT': 'Austria',
    'CH': 'Switzerland',
    'IT': 'Italy',
    'FR': 'France',
    'GB': 'United Kingdom',
    'OTHER': 'Other',
  };

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || saving) return;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await client.from('listings').insert({
        'owner_id': user.id,
        'category': category,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'country_code': country,
        'city': cityController.text.trim(),
        'contact_method': contactMethod,
        'contact_value': contactMethod == 'in_app'
            ? null
            : contactController.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing submitted for approval!'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish advertisement')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: titleController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Advertisement title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final title = (value ?? '').trim();
                    if (title.length < 5) {
                      return 'Title must have at least 5 characters';
                    }
                    if (title.length > 120) {
                      return 'Title cannot exceed 120 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  maxLength: 3000,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final description = (value ?? '').trim();
                    if (description.length < 10) {
                      return 'Description must have at least 10 characters';
                    }
                    if (description.length > 3000) {
                      return 'Description cannot exceed 3000 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'jobs',
                      child: Text('Jobs'),
                    ),
                    DropdownMenuItem(
                      value: 'rides',
                      child: Text('Transport'),
                    ),
                    DropdownMenuItem(
                      value: 'housing',
                      child: Text('Housing'),
                    ),
                    DropdownMenuItem(
                      value: 'services',
                      child: Text('Services'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: country,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: countries.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => country = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: cityController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'City is required'
                          : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: contactMethod,
                  decoration: const InputDecoration(
                    labelText: 'Contact method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'in_app',
                      child: Text('In-app contact'),
                    ),
                    DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text('WhatsApp'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => contactMethod = value);
                    }
                  },
                ),
                if (contactMethod != 'in_app') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact details',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (contactMethod != 'in_app' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Contact details are required';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: saving ? null : submit,
                  icon: const Icon(Icons.send),
                  label: Text(
                    saving
                        ? 'Submitting...'
                        : 'Submit for approval',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your advertisement will become public '
                  'only after administrator approval.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




