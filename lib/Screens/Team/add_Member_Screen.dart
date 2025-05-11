import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMember extends StatefulWidget {
  const AddMember({super.key});

  @override
  State<AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String selectedRole = '';
  bool _isLoading = false;

  Future<void> addMemberToFirestore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('team').add({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'role': selectedRole,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Member added successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add member: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Member",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        toolbarHeight: 90,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fill in the details below to invite a new team member.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  buildTextField(
                    label: "First Name",
                    hint: "Enter your first name",
                    controller: firstNameController,
                    validator: (value) =>
                        value!.isEmpty ? "Please enter First Name" : null,
                  ),

                  const SizedBox(height: 20),
                  buildTextField(
                    label: "Last Name",
                    hint: "Enter your last name",
                    controller: lastNameController,
                    validator: (value) =>
                        value!.isEmpty ? "Please enter Last Name" : null,
                  ),

                  const SizedBox(height: 20),

                  buildTextField(
                    label: "Email",
                    hint: "Enter your email",
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      } else if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
                  buildTextField(
                    label: "Password",
                    hint: "Enter your password",
                    controller: passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter Password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Role",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Radio(
                        value: "Admin",
                        groupValue: selectedRole,
                        onChanged: (value) {
                          setState(() => selectedRole = value.toString());
                        },
                        activeColor: Colors.blue,
                      ),
                      const Text("Admin", style: TextStyle(fontSize: 16)),
                    ],
                  ),

                  Row(
                    children: [
                      Radio(
                        value: "Employee",
                        groupValue: selectedRole,
                        onChanged: (value) {
                          setState(() => selectedRole = value.toString());
                        },
                        activeColor: Colors.blue,
                      ),
                      const Text("Employee", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                if (selectedRole.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please select a role"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  addMemberToFirestore();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLoading ? Colors.grey : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Invite",
                              style:
                                  TextStyle(fontSize: 30, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      validator: validator,
    );
  }
}
