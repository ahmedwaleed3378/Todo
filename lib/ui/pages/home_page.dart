import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../services/notification_services.dart';
import '../../services/theme_services.dart';
import '../size_config.dart';
import '../theme.dart';
import '../widgets/button.dart';
import '../widgets/task_tile.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NotifyHelper notifyHelper;
  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.requestIOSPermissions();
    notifyHelper.initializeNotification();

    _taskController.getTasks();
  }

  final TaskController _taskController = Get.put(TaskController());
  DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        backgroundColor: context.theme.backgroundColor,
        appBar: appbar(),
        body: Column(
          children: [
            _addtaskBar(),
            _addDateBar(),
            const SizedBox(
              height: 20,
            ),
            _showTasks(),
          ],
        ));
  }

  AppBar appbar() => AppBar(
          actions: [
            IconButton(
              icon: Icon(
                Icons.cleaning_services,
                size: 24,
                color: Get.isDarkMode ? Colors.white : darkGreyClr,
              ),
              onPressed: () {
                notifyHelper.cancelAllNotification();
                _taskController.deleteAllTasks();
              },
            ),
            const CircleAvatar(
              backgroundImage: AssetImage('images/person.jpeg'),
            ),
            const SizedBox(
              width: 20,
            )
          ],
          elevation: 0,
          backgroundColor: context.theme.backgroundColor,
          leading: IconButton(
            icon: Icon(
              Get.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round_rounded,
              size: 24,
              color: Get.isDarkMode ? Colors.white : darkGreyClr,
            ),
            onPressed: () {
              ThemeServices().switchTheme();
              /* NotifyHelper().dispalyNotification(
                  title: 'theme changed', body: 'theme changed');*/
              //  NotifyHelper().scheduledNotifications();
            },
          ));

  _addtaskBar() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(DateTime.now()).toString(),
                style: headingStyle,
              ),
              Text(
                'Today',
                style: headingStyle,
              ),
            ],
          ),
          MyButton(
            label: '+ Add Task',
            onTab: () async {
              await Get.to(() => const AddTaskPage());
              _taskController.getTasks();
            },
          )
        ],
      ),
    );
  }

  _addDateBar() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: DatePicker(
        DateTime.now(),
        width: 80,
        height: 100,
        selectedTextColor: Colors.white,
        selectionColor: primaryClr,
        onDateChange: (newDate) {
          setState(() {
            selectedDate = newDate;
          });
        },
        dateTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
                color: Colors.grey, fontSize: 20, fontWeight: FontWeight.w600)),
        monthTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
                color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
        dayTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
                color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
        initialSelectedDate: selectedDate,
      ),
    );
  }

  Future<void> _onRefresh() async {
    _taskController.getTasks();
  }

  // bool taskedday() {
  //   return _taskController.taskList.any((element) =>
  //       (element.date == DateFormat().add_yMd().format(selectedDate))
  //           ? false
  //           : true);
  // }

  _showTasks() {
    return Expanded(
      child: Obx(() {
        if (_taskController.taskList.isEmpty /*|| taskedday()*/) {
          return _notTasks();
        } else {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              scrollDirection: SizeConfig.orientation == Orientation.landscape
                  ? Axis.horizontal
                  : Axis.vertical,
              itemCount: _taskController.taskList.length,
              itemBuilder: (context, index) {
                var task = _taskController.taskList[index];

                if (task.repeat == 'Daily' ||
                    task.date == DateFormat().add_yMd().format(selectedDate) ||
                    (task.repeat == 'Weekly' &&
                        selectedDate
                                    .difference(DateFormat()
                                        .add_yMd()
                                        .parse(task.date!))
                                    .inDays %
                                7 ==
                            0) ||
                    (task.repeat == 'Monthly' &&
                        DateFormat.yMd().parse(task.date!).day ==
                            selectedDate)) {
                  var hour = task.startTime.toString().split(':')[0];
                  var minutes = task.startTime.toString().split(':')[1];
                  notifyHelper.scheduledNotification(
                      int.parse(hour), int.parse(minutes.split('')[0]), task);
                  return AnimationConfiguration.staggeredList(
                    duration: Duration(milliseconds: 800),
                    position: index,
                    child: SlideAnimation(
                      horizontalOffset: 300,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () => showBottomSheet(context, task),
                          child: TaskTile(task),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          );
        }
      }),
    );
  }

  _notTasks() {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(microseconds: 2000),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: SizeConfig.orientation == Orientation.landscape
                    ? Axis.horizontal
                    : Axis.vertical,
                children: [
                  SizeConfig.orientation == Orientation.landscape
                      ? SizedBox(height: 6)
                      : SizedBox(height: 100),
                  SvgPicture.asset(
                    'images/task.svg',
                    height: 90,
                    color: primaryClr.withOpacity(0.5),
                  ),
                  Text(
                    'You do not have any task yet!\n add new task to make your days productive',
                    style: subtitleStyle,
                    textAlign: TextAlign.center,
                  ),
                  SizeConfig.orientation == Orientation.landscape
                      ? SizedBox(height: 120)
                      : SizedBox(height: 180),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _buildBottomSheet(
      {required String label,
      required Function() onTap,
      required Color clr,
      bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        height: 65,
        width: SizeConfig.screenWidth * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
              width: 2,
              color: isClose
                  ? Get.isDarkMode
                      ? Colors.grey[600]!
                      : Colors.grey[300]!
                  : clr),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : clr,
        ),
        child: Center(
          child: Text(
            label,
            style:
                isClose ? titleStyle : titleStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.only(top: 4),
            width: SizeConfig.screenWidth,
            height: (SizeConfig.orientation == Orientation.landscape)
                ? (task.isCompleted == 1
                    ? SizeConfig.screenHeight * 0.6
                    : SizeConfig.screenHeight * 0.8)
                : (task.isCompleted == 1
                    ? SizeConfig.screenHeight * 0.30
                    : SizeConfig.screenHeight * 0.39),
            color: Get.isDarkMode ? darkHeaderClr : Colors.white,
            child: Center(
              child: Column(
                children: [
                  Flexible(
                      child: Container(
                    height: 6,
                    width: 120,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Get.isDarkMode
                            ? Colors.grey[600]
                            : Colors.grey[300]),
                  )),
                  const SizedBox(
                    height: 10,
                  ),
                  task.isCompleted == 1
                      ? Container()
                      : _buildBottomSheet(
                          label: 'Task completed',
                          onTap: () {
                            _taskController.markAsCompleted(task.id!);
                            Get.back();
                          },
                          clr: primaryClr),
                  _buildBottomSheet(
                      label: 'Delete ',
                      onTap: () {
                        notifyHelper.cancelNotification(task);
                        _taskController.deleteTasks(task);
                        Get.back();
                      },
                      clr: Colors.red[300]!),
                  _buildBottomSheet(
                      label: 'Cancel ',
                      onTap: () {
                        Get.back();
                      },
                      clr: primaryClr),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            )),
      ),
    );
  }
}
// import 'package:date_picker_timeline/date_picker_timeline.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:todo/controllers/task_controller.dart';
// import 'package:todo/models/task.dart';
// import 'package:todo/services/notification_services.dart';
// import 'package:todo/services/theme_services.dart';
// import 'package:todo/ui/pages/add_task_page.dart';
// import 'package:todo/ui/size_config.dart';
// import 'package:todo/ui/widgets/button.dart';
// import 'package:intl/intl.dart';
// import 'package:todo/ui/widgets/task_tile.dart';
// import '../theme.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   late NotifyHelper notifyhelper = NotifyHelper();
//   @override
//   void initState() {
//     super.initState();
//     notifyhelper = NotifyHelper();
//     notifyhelper.requestIOSPermissions();
//     notifyhelper.initializeNotification();
//     _taskController.getTasks();
//   }

//   DateTime _selecteddate = DateTime.now();
//   final TaskController _taskController = Get.put(TaskController());
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(
//       backgroundColor: context.theme.backgroundColor,
//       appBar: _appBar(),
//       body: Column(
//         children: [
//           _addTaskBar(),
//           _addDateBar(),
//           const SizedBox(
//             height: 8,
//           ),
//           _showTasks(),
//         ],
//       ),
//     );
//   }

//   AppBar _appBar() {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: context.theme.backgroundColor,
//       leading: ElevatedButton(
//           style: ButtonStyle(
//               backgroundColor:
//                   MaterialStateProperty.all(context.theme.backgroundColor)),
//           onPressed: () {
//             ThemeServices().switchTheme();
//             // notifyhelper.displayNotification(
//             //     title: 'ToDO', body: 'theme changed');
//             // notifyhelper.scheduledNotification(hour, minutes, task);
//           },
//           child: Icon(
//             Get.isDarkMode
//                 ? Icons.wb_sunny_outlined
//                 : Icons.nightlight_round_outlined,
//             size: 24,
//             color: primaryClr,
//           )),
//       actions: const [
//         CircleAvatar(
//           backgroundImage: AssetImage('images/person.jpeg'),
//           radius: 18,
//         ),
//         SizedBox(
//           width: 20,
//         )
//       ],
//     );
//   }

//   _addTaskBar() {
//     return Container(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat.yMMMMd().format(DateTime.now()),
//                 style: subheadingStyle,
//               ),
//               Text('Today', style: headingStyle)
//             ],
//           ),
//           MyButton(
//             label: '+ Add Task',
//             onTab: () async {
//               await Get.to(const AddTaskPage());
//               _taskController.getTasks();
//             },
//           ),
//         ],
//       ),
//       margin: const EdgeInsets.only(right: 10, left: 20, top: 10),
//     );
//   }

//   _addDateBar() {
//     return Container(
//       margin: const EdgeInsets.only(top: 6, left: 20),
//       child: DatePicker(
//         DateTime.now(),
//         width: 70,
//         height: 100,
//         selectedTextColor: Colors.white,
//         selectionColor: primaryClr,
//         initialSelectedDate: DateTime.now(),
//         onDateChange: (newdate) {
//           setState(() {
//             _selecteddate = newdate;
//           });
//         },
//         dateTextStyle: GoogleFonts.lato(
//             textStyle: const TextStyle(
//                 fontWeight: FontWeight.w600, fontSize: 20, color: Colors.grey)),
//         dayTextStyle: GoogleFonts.lato(
//             textStyle: const TextStyle(
//                 fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey)),
//         monthTextStyle: GoogleFonts.lato(
//             textStyle: const TextStyle(
//                 fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
//       ),
//     );
//   }

// //  {
// //
//   _showTasks() {
//     return Expanded(child: Obx(() {
//       if (_taskController.taskList.isEmpty) {
//         return _noTaskmsg();
//       } else {
//         return ListView.builder(
//           physics: const BouncingScrollPhysics(),
//           scrollDirection: SizeConfig.orientation == Orientation.landscape
//               ? Axis.horizontal
//               : Axis.vertical,
//           itemCount: _taskController.taskList.length,
//           itemBuilder: (context, index) {
//             var task = _taskController.taskList[index];

//             // if (task.repeat == 'Daily' ||
//             //     task.date == DateFormat().add_yMd().format(_selecteddate) ||
//             //     (task.repeat == 'Weekly' &&
//             //         _selecteddate
//             //                     .difference(
//             //                         DateFormat().add_yMd().parse(task.date!))
//             //                     .inDays %
//             //                 7 ==
//             //             0) ||
//             //     (task.repeat == 'Monthly' &&
//             //         DateFormat().parse(task.date!).day == _selecteddate)) {
//             var hour = task.startTime.toString().split(':')[0];
//             var minutes = task.startTime.toString().split(':')[1];
//             notifyhelper.scheduledNotification(
//                 int.parse(hour), int.parse(minutes.split('')[0]), task);
//             return AnimationConfiguration.staggeredList(
//               duration: Duration(milliseconds: 800),
//               position: index,
//               child: SlideAnimation(
//                 horizontalOffset: 300,
//                 child: FadeInAnimation(
//                   child: GestureDetector(
//                     onTap: () => _showbottomsheet(context, task),
//                     child: TaskTile(task),
//                   ),
//                 ),
//               ),
//             );
//             //}
//             // else {
//             //   return Container();
//             // }
//           },
//         );
//       }
//     }));
//   }
// // _showtasks() {
// //   return ListView.builder(
// //     shrinkWrap: true,
// //     scrollDirection: SizeConfig.orientation == Orientation.landscape
// //         ? Axis.horizontal
// //         : Axis.vertical,
// //     itemBuilder: (BuildContext context, index) {
// //       Task task = _taskController.tasklist[index];
// //       var date = DateFormat.jm().parse(task.startTime!);
// //       var mytime = DateFormat('HH:mm').format(date);
// //       notifyhelper.scheduledNotification(int.parse(mytime.toString()[0]),
// //           int.parse(mytime.toString()[1]), task);
// //       return AnimationConfiguration.staggeredList(
// //         duration: const Duration(milliseconds: 500),
// //         position: index,
// //         child: SlideAnimation(
// //           horizontalOffset: 300,
// //           child: FadeInAnimation(
// //             duration: const Duration(milliseconds: 200),
// //             child: GestureDetector(
// //               onTap: _showbottomsheet(
// //                 context,
// //                 task,
// //               ),
// //               child: TaskTile(task),
// //             ),
// //           ),
// //         ),
// //       );
// //     },
// //     itemCount: _taskController.tasklist.length,
// //   );
// // return Expanded(
// //   child: ListView.builder(
// //     scrollDirection: SizeConfig.orientation == Orientation.landscape
// //         ? Axis.horizontal
// //         : Axis.vertical,
// //     itemBuilder: (context, index) {
// //       Task task = _taskController.tasklist[index];
// //       var hour = task.startTime.toString().split(':')[0];
// //       var minute = task.startTime.toString().split(':')[1];
// //       debugPrint('My Time is ' + hour);
// //       debugPrint('My minutes is ' + minute);
// //       var date = DateFormat.jm().parse(task.startTime!);
// //       var mytime = DateFormat('HH:mm').format(date);
// //       notifyhelper.scheduledNotification(int.parse(mytime.toString()[0]),
// //           int.parse(mytime.toString()[1]), task);

// //       return AnimationConfiguration.staggeredList(
// //         duration: const Duration(milliseconds: 500),
// //         position: index,
// //         child: SlideAnimation(
// //           horizontalOffset: 300,
// //           child: FadeInAnimation(
// //             duration: const Duration(milliseconds: 200),
// //             child: GestureDetector(
// //               onTap: _showbottomsheet(
// //                 context,
// //                 task,
// //               ),
// //               child: TaskTile(task),
// //             ),
// //           ),
// //         ),
// //       );
// //     },
// //     itemCount: _taskController.tasklist.length,
// //   ),
// // );
// // return Expanded(
// //   child: GestureDetector(
// //     onTap: () => _showbottomsheet(
// //         context,
// //         Task(
// //           title: 'Title 1',
// //           note: ' this is a note ',
// //           isCompleted: 0,
// //           startTime: '8:18',
// //           endTime: '2:40',
// //           color: 1,
// //         )),
// //     child: TaskTile(Task(
// //       title: 'Title 1',
// //       note: ' this is a note ',
// //       isCompleted: 0,
// //       startTime: '8:18',
// //       endTime: '2:40',
// //       color: 1,
// //     )),
// //   ),
// // );
// // Obx(() {
// //   if (_taskController.tasklist.isEmpty) {
// //     return _noTaskmsg();
// //   } else {
// //     return Container(
// //       height: 0,
// //     );
// //   }
// // })
// //}

//   Widget _noTaskmsg() {
//     return Stack(
//       children: [
//         AnimatedPositioned(
//           duration: const Duration(milliseconds: 1000),
//           child: SingleChildScrollView(
//             child: Wrap(
//               alignment: WrapAlignment.center,
//               crossAxisAlignment: WrapCrossAlignment.center,
//               direction: SizeConfig.orientation == Orientation.portrait
//                   ? Axis.vertical
//                   : Axis.horizontal,
//               children: [
//                 SizeConfig.orientation == Orientation.landscape
//                     ? const SizedBox(
//                         height: 6,
//                       )
//                     : const SizedBox(
//                         height: 220,
//                       ),
//                 SvgPicture.asset(
//                   'images/task.svg',
//                   height: 90,
//                   semanticsLabel: 'task',
//                   color: primaryClr.withOpacity(0.5),
//                 ),
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//                   child: Text(
//                     'You don\'t have any tasks yet\nAdd tasks to increase your productitvity',
//                     style: subtitleStyle,
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 SizeConfig.orientation == Orientation.landscape
//                     ? const SizedBox(
//                         height: 120,
//                       )
//                     : const SizedBox(
//                         height: 180,
//                       ),
//               ],
//             ),
//           ),
//         )
//       ],
//     );
//   }

//   _buildbottomsheet(
//       {required String label,
//       required Function() ontap,
//       required Color clr,
//       bool isClose = false}) {
//     return GestureDetector(
//       onTap: ontap,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         width: SizeConfig.screenWidth * 0.9,
//         height: 65,
//         decoration: BoxDecoration(
//             border: Border.all(
//               width: 2,
//               color: isClose
//                   ? Get.isDarkMode
//                       ? Colors.grey[600]!
//                       : Colors.grey[300]!
//                   : clr,
//             ),
//             borderRadius: BorderRadius.circular(20)),
//         child: Center(
//           child: Text(
//             label,
//             style:
//                 isClose ? titleStyle : titleStyle.copyWith(color: Colors.white),
//           ),
//         ),
//       ),
//     );
//   }

//   _showbottomsheet(BuildContext context, Task task) {
//     return Get.bottomSheet(SingleChildScrollView(
//       child: Container(
//         padding: const EdgeInsets.only(top: 4),
//         width: SizeConfig.screenWidth,
//         height: SizeConfig.orientation == Orientation.landscape
//             ? task.isCompleted == 1
//                 ? SizeConfig.screenHeight * 0.6
//                 : SizeConfig.screenHeight * 0.8
//             : task.isCompleted == 1
//                 ? SizeConfig.screenHeight * 0.3
//                 : SizeConfig.screenHeight * 0.4,
//         color: Get.isDarkMode ? darkHeaderClr : Colors.white,
//         child: Column(
//           children: [
//             Flexible(
//                 child: Container(
//               height: 6,
//               width: 120,
//               decoration: BoxDecoration(
//                   color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
//                   borderRadius: BorderRadius.circular(10)),
//             )),
//             const SizedBox(
//               height: 20,
//             ),
//             task.isCompleted == 1
//                 ? Container()
//                 : _buildbottomsheet(
//                     label: 'Task Completed',
//                     ontap: () {
//                       Get.back();
//                     },
//                     clr: primaryClr),
//             _buildbottomsheet(
//                 label: 'Delete Task',
//                 ontap: () {
//                   Get.back();
//                 },
//                 clr: primaryClr),
//             Divider(
//               color: Get.isDarkMode ? Colors.grey : darkGreyClr,
//             ),
//             _buildbottomsheet(
//                 label: 'Cancel',
//                 ontap: () {
//                   Get.back();
//                 },
//                 clr: primaryClr),
//             const SizedBox(
//               height: 20,
//             ),
//           ],
//         ),
//       ),
//     ));
//   }
// }
