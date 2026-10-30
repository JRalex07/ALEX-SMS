import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../models/admission_application_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class AdmissionApplicationScreen extends ConsumerStatefulWidget {
  final String? applicationId;

  const AdmissionApplicationScreen({super.key, this.applicationId});

  @override
  ConsumerState<AdmissionApplicationScreen> createState() =>
      _AdmissionApplicationScreenState();
}

class _AdmissionApplicationScreenState
    extends ConsumerState<AdmissionApplicationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSavingDraft = false;
  late String _appId;

  // Step 0: Applicant
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  DateTime _dob = DateTime(2015, 5, 15);
  String _gender = 'Male';
  String _bloodGroup = 'O+';
  final _nationalityCtrl = TextEditingController(text: 'Indian');
  final _motherTongueCtrl = TextEditingController(text: 'English');
  final _aadhaarCtrl = TextEditingController();
  String? _photoUrl;

  // Step 1: Parents & Guardians
  final _fatherNameCtrl = TextEditingController();
  final _fatherOccCtrl = TextEditingController();
  final _fatherPhoneCtrl = TextEditingController();
  final _fatherEmailCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherOccCtrl = TextEditingController();
  final _motherPhoneCtrl = TextEditingController();
  final _motherEmailCtrl = TextEditingController();
  String _primaryGuardian = 'Father';
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  String _emergencyRelation = 'Father';

  // Step 2: Address
  final _houseNumberCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Jaipur');
  final _districtCtrl = TextEditingController(text: 'Jaipur');
  final _stateCtrl = TextEditingController(text: 'Rajasthan');
  final _postalCodeCtrl = TextEditingController(text: '302001');
  bool _samePermanent = true;
  final _permAddressCtrl = TextEditingController();

  // Step 3: Academic
  String _academicYear = 'AY-2026-2027';
  String _targetClass = '10';
  String _targetSection = 'A';
  final _prevSchoolCtrl = TextEditingController();
  final _prevSchoolAddressCtrl = TextEditingController();
  final _prevClassCtrl = TextEditingController();
  final _prevResultCtrl = TextEditingController();
  final _tcNumberCtrl = TextEditingController();
  DateTime? _tcDate;
  final _reasonLeavingCtrl = TextEditingController();

  // Step 4: Preferences & Referral
  String _category = 'General';
  DateTime _requestedDate = DateTime(2026, 4, 1);
  String _referral = 'Website';

  // Step 5: Documents
  List<UploadedDocument> _uploadedDocs = [];
  final Map<String, bool> _uploadingMap = {};

  // Step 6: Declaration
  bool _declarationAccepted = false;

  final List<String> _stepTitles = [
    'Student Details',
    'Parents & Guardians',
    'Addresses',
    'Academic History',
    'Admission Preferences',
    'Upload Documents',
    'Review & Submit',
  ];

  @override
  void initState() {
    super.initState();
    final repo = ref.read(admissionRepositoryProvider);
    _appId = widget.applicationId ?? repo.generateApplicationId();

    if (widget.applicationId != null) {
      _loadExistingApplication(widget.applicationId!);
    }
  }

  Future<void> _loadExistingApplication(String id) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(admissionRepositoryProvider);
      final app = await repo.getApplicationById(id);
      if (app != null) {
        _populateFields(app);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Failed to load application draft: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields(AdmissionApplication app) {
    _firstNameCtrl.text = app.firstName;
    _middleNameCtrl.text = app.middleName;
    _lastNameCtrl.text = app.lastName;
    _dob = app.dateOfBirth;
    _gender = app.gender;
    _bloodGroup = app.bloodGroup;
    _nationalityCtrl.text = app.nationality;
    _motherTongueCtrl.text = app.motherTongue;
    _aadhaarCtrl.text = app.studentAadhaarNumber ?? '';
    _photoUrl = app.photoUrl;

    _fatherNameCtrl.text = app.fatherName;
    _fatherOccCtrl.text = app.fatherOccupation;
    _fatherPhoneCtrl.text = app.fatherPhone;
    _fatherEmailCtrl.text = app.fatherEmail;
    _motherNameCtrl.text = app.motherName;
    _motherOccCtrl.text = app.motherOccupation;
    _motherPhoneCtrl.text = app.motherPhone;
    _motherEmailCtrl.text = app.motherEmail;
    _primaryGuardian = app.primaryGuardian;
    _emergencyNameCtrl.text = app.emergencyContactName;
    _emergencyPhoneCtrl.text = app.emergencyContactPhone;
    _emergencyRelation = app.emergencyContactRelation;

    _houseNumberCtrl.text = app.houseNumber;
    _streetCtrl.text = app.streetLocality;
    _cityCtrl.text = app.city;
    _districtCtrl.text = app.district;
    _stateCtrl.text = app.state;
    _postalCodeCtrl.text = app.postalCode;
    _samePermanent = app.isPermanentSameAsCurrent;
    _permAddressCtrl.text = app.permanentAddress;

    _academicYear = app.academicYearId;
    _targetClass = app.targetClass;
    _targetSection = app.targetSection;
    _prevSchoolCtrl.text = app.previousSchoolName;
    _prevSchoolAddressCtrl.text = app.previousSchoolAddress;
    _prevClassCtrl.text = app.previousClass;
    _prevResultCtrl.text = app.previousResultPercentage;
    _tcNumberCtrl.text = app.transferCertificateNumber;
    _tcDate = app.transferCertificateDate;
    _reasonLeavingCtrl.text = app.reasonForLeaving;

    _category = app.admissionCategory;
    _requestedDate = app.requestedAdmissionDate;
    _referral = app.referralSource;
    _uploadedDocs = List.from(app.documents);
  }

  AdmissionApplication _buildCurrentApplication({required bool isDraft}) {
    final full =
        '${_firstNameCtrl.text.trim()} ${_middleNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
            .trim();
    return AdmissionApplication(
      id: _appId,
      fullName: full.isEmpty ? 'Prospective Applicant' : full,
      firstName: _firstNameCtrl.text.trim(),
      middleName: _middleNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      bloodGroup: _bloodGroup,
      nationality: _nationalityCtrl.text.trim(),
      motherTongue: _motherTongueCtrl.text.trim(),
      studentAadhaarNumber: _aadhaarCtrl.text.trim(),
      photoUrl: _photoUrl,
      fatherName: _fatherNameCtrl.text.trim(),
      fatherOccupation: _fatherOccCtrl.text.trim(),
      fatherPhone: _fatherPhoneCtrl.text.trim(),
      fatherEmail: _fatherEmailCtrl.text.trim(),
      motherName: _motherNameCtrl.text.trim(),
      motherOccupation: _motherOccCtrl.text.trim(),
      motherPhone: _motherPhoneCtrl.text.trim(),
      motherEmail: _motherEmailCtrl.text.trim(),
      primaryGuardian: _primaryGuardian,
      guardianName: _primaryGuardian == 'Father'
          ? _fatherNameCtrl.text.trim()
          : _motherNameCtrl.text.trim(),
      guardianPhone: _primaryGuardian == 'Father'
          ? _fatherPhoneCtrl.text.trim()
          : _motherPhoneCtrl.text.trim(),
      guardianEmail: _primaryGuardian == 'Father'
          ? _fatherEmailCtrl.text.trim()
          : _motherEmailCtrl.text.trim(),
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      emergencyContactRelation: _emergencyRelation,
      houseNumber: _houseNumberCtrl.text.trim(),
      streetLocality: _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim(),
      permanentAddress: _samePermanent ? '' : _permAddressCtrl.text.trim(),
      isPermanentSameAsCurrent: _samePermanent,
      academicYearId: _academicYear,
      targetClass: _targetClass,
      targetSection: _targetSection,
      previousSchoolName: _prevSchoolCtrl.text.trim(),
      previousSchoolAddress: _prevSchoolAddressCtrl.text.trim(),
      previousClass: _prevClassCtrl.text.trim(),
      previousResultPercentage: _prevResultCtrl.text.trim(),
      transferCertificateNumber: _tcNumberCtrl.text.trim(),
      transferCertificateDate: _tcDate,
      reasonForLeaving: _reasonLeavingCtrl.text.trim(),
      admissionCategory: _category,
      requestedAdmissionDate: _requestedDate,
      referralSource: _referral,
      documents: _uploadedDocs,
      status: isDraft ? 'draft' : 'submitted',
      isDraft: isDraft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      submittedAt: isDraft ? null : DateTime.now(),
    );
  }

  Future<void> _handleSaveDraft() async {
    setState(() => _isSavingDraft = true);
    try {
      final repo = ref.read(admissionRepositoryProvider);
      final app = _buildCurrentApplication(isDraft: true);
      await repo.saveDraft(app);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            content: Text(
                'Application Draft saved successfully! Reference: ${app.id}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Failed to save draft: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the statutory declaration.')),
      );
      return;
    }

    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Student first and last name are required.')),
      );
      return;
    }

    if (_fatherPhoneCtrl.text.trim().isEmpty &&
        _motherPhoneCtrl.text.trim().isEmpty) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('At least one parent phone number is required.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(admissionRepositoryProvider);
      final app = _buildCurrentApplication(isDraft: false);
      await repo.submitApplication(app);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.successGreen, size: 28),
                SizedBox(width: 12),
                Text('Application Submitted'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application for ${app.fullName} has been submitted for official review.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Application Reference Number:',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        app.id,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandNavy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The Admissions Office will verify submitted documents and schedule assessment / interview.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Print Preview'),
                onPressed: () {
                  PrintPreviewDialog.showAdmissionApplication(context,
                      application: app);
                },
              ),
              FilledButton(
                child: const Text('Return to Admissions Desk'),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.admissions);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadDocument(String docType) async {
    setState(() => _uploadingMap[docType] = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (file == null) {
        setState(() => _uploadingMap[docType] = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File data could not be read.');
      }

      // Check max size: 5MB
      final size = file.lengthSync() ?? bytes.length;
      if (size > 5 * 1024 * 1024) {
        throw Exception('File exceeds maximum allowed size of 5 MB.');
      }

      final repo = ref.read(admissionRepositoryProvider);
      final uploaded = await repo.uploadDocument(
        applicationId: _appId,
        documentType: docType,
        fileName: file.name,
        bytes: bytes,
      );

      setState(() {
        _uploadedDocs.removeWhere((d) => d.documentType == docType);
        _uploadedDocs.add(uploaded);
        if (docType == 'photo') {
          _photoUrl = uploaded.fileUrl;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            content: Text('${file.name} uploaded and verified in Storage!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingMap[docType] = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nationalityCtrl.dispose();
    _motherTongueCtrl.dispose();
    _aadhaarCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherOccCtrl.dispose();
    _fatherPhoneCtrl.dispose();
    _fatherEmailCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherOccCtrl.dispose();
    _motherPhoneCtrl.dispose();
    _motherEmailCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _houseNumberCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _postalCodeCtrl.dispose();
    _permAddressCtrl.dispose();
    _prevSchoolCtrl.dispose();
    _prevSchoolAddressCtrl.dispose();
    _prevClassCtrl.dispose();
    _prevResultCtrl.dispose();
    _tcNumberCtrl.dispose();
    _reasonLeavingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return ResponsiveScaffold(
      title: 'New Student Admission Application',
      currentRoute: AppRoutes.admissions,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.print_outlined, size: 16),
          label: const Text('Print Preview'),
          onPressed: () {
            final app = _buildCurrentApplication(isDraft: true);
            PrintPreviewDialog.showAdmissionApplication(context,
                application: app);
          },
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          icon: _isSavingDraft
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save Draft'),
          onPressed: _isSavingDraft ? null : _handleSaveDraft,
        ),
        const SizedBox(width: 8),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 36 : 16,
                vertical: 24,
              ),
              children: [
                _buildHeaderStrip(),
                const SizedBox(height: 20),
                Stepper(
                  physics: const ClampingScrollPhysics(),
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: () {
                    if (_currentStep < _stepTitles.length - 1) {
                      setState(() => _currentStep++);
                    } else {
                      _handleSubmit();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                  },
                  controlsBuilder: (context, details) {
                    final isLast = _currentStep == _stepTitles.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        children: [
                          if (_currentStep > 0) ...[
                            OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                            const SizedBox(width: 12),
                          ],
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isLast
                                  ? AppColors.successGreen
                                  : AppColors.brandNavy,
                            ),
                            onPressed: details.onStepContinue,
                            child: Text(
                                isLast ? 'Submit Application' : 'Continue'),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Applicant & Student Profile'),
                      subtitle: const Text(
                          'Full legal name, DOB, blood group & demographics'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildApplicantStep(),
                    ),
                    Step(
                      title: const Text('Parents & Guardians'),
                      subtitle: const Text(
                          'Father, Mother, emergency contact & primary guardian'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildGuardianStep(),
                    ),
                    Step(
                      title: const Text('Residential Addresses'),
                      subtitle:
                          const Text('Present and permanent domicile records'),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildAddressStep(),
                    ),
                    Step(
                      title: const Text('Academic History & Background'),
                      subtitle: const Text(
                          'Target class, previous school & transfer details'),
                      isActive: _currentStep >= 3,
                      state: _currentStep > 3
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildAcademicStep(),
                    ),
                    Step(
                      title: const Text('Preferences & Referral'),
                      subtitle: const Text(
                          'Admission quota, requested joining date & referral source'),
                      isActive: _currentStep >= 4,
                      state: _currentStep > 4
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildPreferencesStep(),
                    ),
                    Step(
                      title: const Text('Statutory Document Uploads'),
                      subtitle: const Text(
                          'Birth certificate, photograph, marksheet & ID proofs'),
                      isActive: _currentStep >= 5,
                      state: _currentStep > 5
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildDocumentsStep(),
                    ),
                    Step(
                      title: const Text('Review & Final Declaration'),
                      subtitle: const Text(
                          'Summary review and parent declaration confirmation'),
                      isActive: _currentStep >= 6,
                      state: StepState.indexed,
                      content: _buildReviewStep(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStrip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_ind,
                color: AppColors.brandNavy, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('APPLICATION REF: $_appId',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('DRAFT / IN PROGRESS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningAmber)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Complete all 7 sections with verified legal records before submitting for officer moderation.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'First Name *', hintText: 'Aarav'),
            ),
            TextFormField(
              controller: _middleNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Middle Name', hintText: 'Kumar'),
            ),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Last Name *', hintText: 'Sharma'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 14,
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob,
                  firstDate: DateTime(2005),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dob = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth *',
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text('${_dob.day}/${_dob.month}/${_dob.year}'),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender *'),
              items: ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v ?? _gender),
            ),
            DropdownButtonFormField<String>(
              initialValue: _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group *'),
              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _bloodGroup = v ?? _bloodGroup),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 14,
          children: [
            TextFormField(
              controller: _nationalityCtrl,
              decoration: const InputDecoration(labelText: 'Nationality *'),
            ),
            TextFormField(
              controller: _motherTongueCtrl,
              decoration: const InputDecoration(labelText: 'Mother Tongue *'),
            ),
            TextFormField(
              controller: _aadhaarCtrl,
              decoration: const InputDecoration(
                  labelText: 'Aadhaar / National ID No.'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuardianStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Father / First Guardian Details',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _fatherNameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Father\'s Full Name *'),
            ),
            TextFormField(
              controller: _fatherOccCtrl,
              decoration:
                  const InputDecoration(labelText: 'Occupation / Business'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _fatherPhoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Father Mobile *', prefixText: '+91 '),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _fatherEmailCtrl,
              decoration: const InputDecoration(labelText: 'Father Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Mother / Second Guardian Details',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _motherNameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Mother\'s Full Name'),
            ),
            TextFormField(
              controller: _motherOccCtrl,
              decoration: const InputDecoration(labelText: 'Occupation'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _motherPhoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Mother Mobile', prefixText: '+91 '),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _motherEmailCtrl,
              decoration: const InputDecoration(labelText: 'Mother Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        const SizedBox(height: 20),
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 14,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _primaryGuardian,
              decoration: const InputDecoration(
                  labelText: 'Primary Contact Guardian *'),
              items: ['Father', 'Mother', 'Other Guardian']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _primaryGuardian = v ?? _primaryGuardian),
            ),
            TextFormField(
              controller: _emergencyNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Emergency Contact Person *'),
            ),
            TextFormField(
              controller: _emergencyPhoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone *', prefixText: '+91 '),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Present Residential Address',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _houseNumberCtrl,
              decoration: const InputDecoration(
                  labelText: 'Flat / House No. *', hintText: '42-B'),
            ),
            TextFormField(
              controller: _streetCtrl,
              decoration: const InputDecoration(
                  labelText: 'Street / Locality *',
                  hintText: 'Central Spine, Sector 2'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdaptiveFormRow(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'City *'),
            ),
            TextFormField(
              controller: _districtCtrl,
              decoration: const InputDecoration(labelText: 'District *'),
            ),
            TextFormField(
              controller: _stateCtrl,
              decoration: const InputDecoration(labelText: 'State *'),
            ),
            TextFormField(
              controller: _postalCodeCtrl,
              decoration: const InputDecoration(labelText: 'PIN Code *'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
              'Permanent domicile is identical to present residential address'),
          value: _samePermanent,
          onChanged: (val) => setState(() => _samePermanent = val ?? true),
        ),
        if (!_samePermanent) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _permAddressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Permanent Residential Address *',
              hintText: 'Enter full permanent address with postal code',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAcademicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 14,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _academicYear,
              decoration: const InputDecoration(
                  labelText: 'Admission Academic Year *'),
              items: ['AY-2026-2027', 'AY-2027-2028']
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _academicYear = v ?? _academicYear),
            ),
            DropdownButtonFormField<String>(
              initialValue: _targetClass,
              decoration:
                  const InputDecoration(labelText: 'Applying for Class *'),
              items: [
                'Pre-K',
                'KG',
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '10',
                '11',
                '12'
              ]
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text('Class $c')))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _targetClass = v ?? _targetClass),
            ),
            DropdownButtonFormField<String>(
              initialValue: _targetSection,
              decoration:
                  const InputDecoration(labelText: 'Preferred Section'),
              items: ['A', 'B', 'C', 'D']
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text('Section $s')))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _targetSection = v ?? _targetSection),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Prior Academic & School Background',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 14,
          children: [
            TextFormField(
              controller: _prevSchoolCtrl,
              decoration: const InputDecoration(
                  labelText: 'Previous School Name',
                  hintText:
                      'St. Xavier Public School (leave blank if fresher)'),
            ),
            TextFormField(
              controller: _prevClassCtrl,
              decoration: const InputDecoration(
                  labelText: 'Last Class Completed', hintText: 'Class 9'),
            ),
            TextFormField(
              controller: _prevResultCtrl,
              decoration: const InputDecoration(
                  labelText: 'Aggregate Result %', hintText: '88.5%'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 12,
          children: [
            TextFormField(
              controller: _tcNumberCtrl,
              decoration: const InputDecoration(
                  labelText: 'Transfer Certificate (TC) No.'),
            ),
            TextFormField(
              controller: _reasonLeavingCtrl,
              decoration: const InputDecoration(
                  labelText: 'Reason for Transfer / Leaving'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveFormRow(
          spacing: 16,
          runSpacing: 14,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                  labelText: 'Admission Category / Quota *'),
              items: [
                'General',
                'Management',
                'Sibling',
                'Staff Child',
                'RTE'
              ]
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _requestedDate,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                );
                if (picked != null) setState(() => _requestedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Requested Joining Date *',
                  suffixIcon: Icon(Icons.event, size: 18),
                ),
                child: Text(
                    '${_requestedDate.day}/${_requestedDate.month}/${_requestedDate.year}'),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _referral,
              decoration: const InputDecoration(
                  labelText: 'Referral / Information Source'),
              items: [
                'Website',
                'Word of Mouth',
                'Social Media',
                'Newspaper',
                'Alumni'
              ]
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _referral = v ?? _referral),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    final docTypes = [
      {
        'key': 'photo',
        'label': 'Student Passport Photograph',
        'required': true
      },
      {
        'key': 'birth_certificate',
        'label': 'Official Municipal Birth Certificate',
        'required': true
      },
      {
        'key': 'transfer_certificate',
        'label': 'Transfer Certificate (TC)',
        'required': false
      },
      {
        'key': 'report_card',
        'label': 'Previous Academic Report Card / Marksheet',
        'required': false
      },
      {
        'key': 'address_proof',
        'label': 'Parent Address Proof (Electricity Bill / Aadhaar)',
        'required': true
      },
      {
        'key': 'guardian_id',
        'label': 'Guardian Photo ID Document',
        'required': true
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload required document scans (PDF, PNG, JPG up to 5MB each). Documents are stored directly in encrypted Firebase Storage linked to this application record.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        for (final item in docTypes) ...[
          _buildDocUploadCard(
            key: item['key'] as String,
            title: item['label'] as String,
            isRequired: item['required'] as bool,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDocUploadCard({
    required String key,
    required String title,
    required bool isRequired,
  }) {
    final existing =
        _uploadedDocs.where((d) => d.documentType == key).firstOrNull;
    final isUploading = _uploadingMap[key] ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: existing != null ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: existing != null
              ? AppColors.successGreen.withValues(alpha: 0.4)
              : AppColors.borderLight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final isNarrow = cardConstraints.maxWidth < 460;
          final actionWidget = isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : existing != null
                  ? Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Replace'),
                          onPressed: () => _pickAndUploadDocument(key),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.dangerRed),
                          tooltip: 'Remove document',
                          onPressed: () {
                            setState(() => _uploadedDocs
                                .removeWhere((d) => d.documentType == key));
                          },
                        ),
                      ],
                    )
                  : FilledButton.tonalIcon(
                      icon: const Icon(Icons.file_upload, size: 16),
                      label: const Text('Select File'),
                      onPressed: () => _pickAndUploadDocument(key),
                    );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      existing != null ? Icons.check_circle : Icons.upload_file,
                      color: existing != null
                          ? AppColors.successGreen
                          : AppColors.brandNavy,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title ${isRequired ? "*" : "(Optional)"}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            existing != null
                                ? 'Uploaded: ${existing.fileName} • ${(existing.fileSizeBytes / 1024).toStringAsFixed(1)} KB'
                                : 'Not yet uploaded',
                            style: TextStyle(
                              fontSize: 11,
                              color: existing != null
                                  ? AppColors.successGreen
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: actionWidget,
                ),
              ],
            );
          }

          return Row(
            children: [
              Icon(
                existing != null ? Icons.check_circle : Icons.upload_file,
                color: existing != null
                    ? AppColors.successGreen
                    : AppColors.brandNavy,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title ${isRequired ? "*" : "(Optional)"}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      existing != null
                          ? 'Uploaded: ${existing.fileName} • ${(existing.fileSizeBytes / 1024).toStringAsFixed(1)} KB'
                          : 'Not yet uploaded',
                      style: TextStyle(
                        fontSize: 11,
                        color: existing != null
                            ? AppColors.successGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              actionWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewStep() {
    final full =
        '${_firstNameCtrl.text.trim()} ${_middleNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
            .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Application Summary',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy)),
              const Divider(height: 20, color: AppColors.borderLight),
              _summaryRow('Application Reference ID', _appId),
              _summaryRow(
                  'Student Legal Name', full.isEmpty ? 'Not entered' : full),
              _summaryRow(
                  'Applying for Class', 'Class $_targetClass ($_academicYear)'),
              _summaryRow('Date of Birth & Gender',
                  '${_dob.day}/${_dob.month}/${_dob.year} • $_gender'),
              _summaryRow('Primary Guardian',
                  '$_primaryGuardian (${_fatherPhoneCtrl.text.isNotEmpty ? _fatherPhoneCtrl.text : _motherPhoneCtrl.text})'),
              _summaryRow('Present City & State',
                  '${_cityCtrl.text}, ${_stateCtrl.text} - ${_postalCodeCtrl.text}'),
              _summaryRow('Uploaded Documents',
                  '${_uploadedDocs.length} files attached'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Statutory Declaration & Authorization',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          subtitle: const Text(
            'I hereby certify that all information submitted in this application is accurate and verified. I understand that any false statement or forged document will result in immediate disqualification and revocation of admission under CBSE bylaws.',
            style: TextStyle(fontSize: 11, height: 1.4),
          ),
          value: _declarationAccepted,
          onChanged: (val) =>
              setState(() => _declarationAccepted = val ?? false),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}