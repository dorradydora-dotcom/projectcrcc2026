import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/projects_controller.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';
import 'package:amiraly/app/util/constant/constants.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProjectsController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Appcolors.primaryColor,
                Appcolors.primaryColor,
                Color(0xFF163C5E),
                Color(0xFF0F2B44),
                Color(0xFF081A2A)
              ],
            ),
          ),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                  child: ElectricLoadingIndicator(color: Colors.white));
            }

            if (!controller.hasAccess.value) {
              return _buildAccessDenied();
            }

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: _buildHeader(controller),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildDashboard(controller),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final project = controller.projects[index];
                          return _buildProjectCard(
                              context, controller, project);
                        },
                        childCount: controller.projects.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButton: Obx(() {
        if (controller.hasAccess.value) {
          return FloatingActionButton.extended(
            onPressed: () => _showProjectDialog(context, controller),
            backgroundColor: Appcolors.buttonColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('مشروع جديد',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: Appfontstring.ChangaLight)),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildHeader(ProjectsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'متابعة المشروعات',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
        Text(
          'إدارة وتتبع مشروعات الشبكة الكهربائية (${controller.projects.length})',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12.sp,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(ProjectsController controller) {
    final totalBudget =
        controller.projects.fold(0.0, (sum, p) => sum + p.totalCost);
    final totalSpent =
        controller.projects.fold(0.0, (sum, p) => sum + p.spentCost);
    final avgProgress = controller.projects.isEmpty
        ? 0.0
        : controller.projects.fold(0.0, (sum, p) => sum + p.progress) /
            controller.projects.length;

    return Container(
      height: 90.h,
      margin: EdgeInsets.only(bottom: 11.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildStatCard(
              'إجمالي الميزانية',
              '${(totalBudget / 1e6).toStringAsFixed(1)}M',
              Icons.account_balance_wallet,
              Colors.blue),
          _buildStatCard(
              'المنصرف الفعلي',
              '${(totalSpent / 1e6).toStringAsFixed(1)}M',
              Icons.payments,
              Colors.orange),
          _buildStatCard('متوسط الإنجاز', '${avgProgress.toInt()}%',
              Icons.speed, Colors.green),
          _buildStatCard(
              'مشروعات نشطة',
              controller.projects
                  .where((p) => p.status == 'in_progress')
                  .length
                  .toString(),
              Icons.pending_actions,
              Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 117.w,
      margin: EdgeInsetsDirectional.only(end: 9.w),
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 5.h),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.ChangaLight)),
          Text(title,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10.sp,
                  fontFamily: Appfontstring.ChangaLight)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectsController controller,
      ProjectModel project) {
    // Generate pastel color based on project index
    final projectIndex = controller.projects.indexOf(project);
    final pastelColors = [
      Colors.blue.withValues(alpha: 0.08),
      Colors.purple.withValues(alpha: 0.08),
      Colors.green.withValues(alpha: 0.08),
      Colors.orange.withValues(alpha: 0.08),
      Colors.pink.withValues(alpha: 0.08),
      Colors.teal.withValues(alpha: 0.08),
      Colors.amber.withValues(alpha: 0.08),
      Colors.indigo.withValues(alpha: 0.08),
    ];
    final cardColor = pastelColors[projectIndex % pastelColors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 11.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: () =>
              _showProjectDialog(context, controller, project: project),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.ChangaLight),
                          ),
                          if (project.description.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Text(
                                project.description,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11.sp,
                                    fontFamily: Appfontstring.ChangaLight),
                              ),
                            ),
                          SizedBox(height: 2.h),
                          Text(
                            'المحطة: ${project.stationName} | الجهد: ${project.voltageLevel}',
                            style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 11.sp,
                                fontFamily: Appfontstring.ChangaLight),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(project.status),
                  ],
                ),
                if (project.notes.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border:
                            Border.all(color: Colors.yellow.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.note, color: Colors.yellow, size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'ملاحظات: ${project.notes}',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                  fontFamily: Appfontstring.ChangaLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('التقدم الحالي',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10.sp,
                            fontFamily: Appfontstring.ChangaLight)),
                    Text('${project.progress.toInt()}%',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                            fontFamily: Appfontstring.ChangaLight)),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: project.progress / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    project.progress < 30
                        ? Colors.red
                        : project.progress < 70
                            ? Colors.orange
                            : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 8,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProjectDetail(
                        Icons.person, 'المسؤول', project.manager),
                    _buildProjectDetail(
                        Icons.business, 'المقاول', project.contractor),
                    _buildProjectDetail(
                        Icons.calendar_today, 'تاريخ البدء', project.startDate),
                  ],
                ),
                const Divider(color: Colors.white10, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCostItem('التكلفة الكلية', project.totalCost),
                    _buildCostItem('المنصرف', project.spentCost,
                        highlight: true),
                    _buildCostItem('المتبقي', project.remainingCost),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'مكتمل';
        break;
      case 'in_progress':
        color = Colors.orange;
        text = 'قيد التنفيذ';
        break;
      case 'delayed':
        color = Colors.red;
        text = 'متأخر';
        break;
      default:
        color = Colors.blue;
        text = 'مخطط';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: Appfontstring.ChangaLight)),
    );
  }

  Widget _buildProjectDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 18.sp),
        SizedBox(height: 4.h),
        Text(label,
            style: TextStyle(
                color: Colors.white38,
                fontSize: 8.sp,
                fontFamily: Appfontstring.ChangaLight)),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                fontFamily: Appfontstring.ChangaLight)),
      ],
    );
  }

  Widget _buildCostItem(String label, double amount, {bool highlight = false}) {
    final formatter = intl.NumberFormat('#,###', 'en_US');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white38,
                fontSize: 8.sp,
                fontFamily: Appfontstring.ChangaLight)),
        Text(
          '${formatter.format(amount)} ج.م',
          style: TextStyle(
            color: highlight ? Colors.orange : Colors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: Colors.red, size: 80.sp),
          SizedBox(height: 16.h),
          Text(
            'دخول غير مصرح',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: Appfontstring.ChangaLight),
          ),
          SizedBox(height: 8.h),
          Text(
            'هذا القسم مخصص للمستخدمين المصرح لهم فقط',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13.sp,
                fontFamily: Appfontstring.ChangaLight),
          ),
        ],
      ),
    );
  }

  Future<void> _showProjectDialog(BuildContext context, ProjectsController controller,
      {ProjectModel? project}) async {
    final nameController = TextEditingController(text: project?.name);
    final descriptionController =
        TextEditingController(text: project?.description);
    final notesController = TextEditingController(text: project?.notes);
    final stationController = TextEditingController(text: project?.stationName);
    final voltageController =
        TextEditingController(text: project?.voltageLevel);
    final managerController = TextEditingController(text: project?.manager);
    final contractorController =
        TextEditingController(text: project?.contractor);
    final totalCostController =
        TextEditingController(text: project?.totalCost.toString());
    final spentCostController =
        TextEditingController(text: project?.spentCost.toString());
    final progress = (project?.progress ?? 0.0).obs;

    // Validate status value - ensure it's one of the allowed values
    const allowedStatuses = ['planned', 'in_progress', 'completed', 'delayed'];
    final initialStatus = project?.status ?? 'planned';
    final validatedStatus =
        allowedStatuses.contains(initialStatus) ? initialStatus : 'planned';
    final status = validatedStatus.obs;

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    project == null ? 'إضافة مشروع جديد' : 'تعديل مشروع',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontFamily: Appfontstring.ChangaLight)),
              ),
              if (project != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'حذف المشروع',
                  onPressed: () {
                    Get.back(); // Close edit dialog
                    _showDeleteConfirmation(context, controller, project.id);
                  },
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(nameController, 'اسم المشروع', Icons.title),
                _buildDialogField(
                    descriptionController, 'وصف المشروع', Icons.description,
                    maxLines: 2),
                _buildDialogField(
                    notesController, 'ملاحظات إضافية', Icons.note_alt,
                    maxLines: 2),
                _buildDialogField(
                    stationController, 'اسم المحطة', Icons.location_on),
                _buildDialogField(voltageController, 'مستوى الجهد', Icons.bolt),
                _buildDialogField(managerController, 'المسؤول', Icons.person),
                _buildDialogField(
                    contractorController, 'المقاول', Icons.business),
                _buildDialogField(
                    totalCostController, 'التكلفة الكلية', Icons.money,
                    isNumber: true),
                _buildDialogField(spentCostController, 'المنصرف', Icons.payment,
                    isNumber: true),
                const SizedBox(height: 16),
                Obx(() => Column(
                      children: [
                        Text('التقدم: ${progress.value.toInt()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: Appfontstring.ChangaLight)),
                        Slider(
                          value: progress.value,
                          min: 0,
                          max: 100,
                          onChanged: (v) => progress.value = v,
                          activeColor: Appcolors.buttonColor,
                        ),
                      ],
                    )),
                Obx(() => DropdownButtonFormField<String>(
                      value: status.value,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        labelText: 'الحالة',
                        labelStyle: const TextStyle(color: Colors.white60),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'planned', child: Text('مخطط')),
                        DropdownMenuItem(
                            value: 'in_progress', child: Text('قيد التنفيذ')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('مكتمل')),
                        DropdownMenuItem(
                            value: 'delayed', child: Text('متأخر')),
                      ],
                      onChanged: (v) => status.value = v!,
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolors.buttonColor),
              onPressed: () {
                final newProject = ProjectModel(
                  id: project?.id ?? '',
                  name: nameController.text,
                  description: descriptionController.text,
                  notes: notesController.text,
                  progress: progress.value,
                  totalCost: double.tryParse(totalCostController.text) ?? 0,
                  spentCost: double.tryParse(spentCostController.text) ?? 0,
                  startDate: project?.startDate ??
                      DateTime.now().toString().split(' ')[0],
                  endDate: project?.endDate ?? '',
                  manager: managerController.text,
                  contractor: contractorController.text,
                  voltageLevel: voltageController.text,
                  stationName: stationController.text,
                  status: status.value,
                );
                if (project == null) {
                  controller.addProject(newProject);
                } else {
                  controller.updateProject(project.id, newProject);
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    stationController.dispose();
    voltageController.dispose();
    managerController.dispose();
    contractorController.dispose();
    totalCostController.dispose();
    spentCostController.dispose();
  }

  Widget _buildDialogField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Appcolors.buttonColor)),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, ProjectsController controller, String projectId) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('تأكيد الحذف',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: Appfontstring.ChangaLight)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا المشروع؟\nلا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: Appfontstring.ChangaLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Get.back(); // Close confirmation dialog
                controller.deleteProject(projectId);
              },
              child: const Text('حذف نهائياً'),
            ),
          ],
        ),
      ),
    );
  }
}
