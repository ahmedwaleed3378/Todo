import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/task_controller.dart';
import 'package:todo/models/task.dart';
import 'package:todo/services/theme_services.dart';
import 'package:todo/ui/theme.dart';
import 'package:todo/ui/widgets/button.dart';
import 'package:todo/ui/widgets/input_field.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskController _taskController = Get.put(TaskController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _stratTime = DateFormat('hh:mm:a').format(DateTime.now()).toString();
  String _endTime = DateFormat('hh:mm:a')
      .format(DateTime.now().add(const Duration(minutes: 15)))
      .toString();
  int _selectedRemind = 0;
  List<int> remindList = [5, 10, 15, 20];
  String _selectedRepeat = 'None';
  List<String> reapeatList = ['None', 'Daily', 'Weekly', 'Monthly'];
  int selectedcolor = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.backgroundColor,
      appBar: _appBar(),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Add Task',
                style: headingStyle,
              ),
              InputField(
                title: 'Title',
                hint: 'Enter Title here',
                controller: _titleController,
              ),
              InputField(
                title: 'Note',
                hint: 'Enter Note here',
                controller: _noteController,
              ),
              InputField(
                title: 'Date',
                hint: DateFormat.yMd().format(_selectedDate),
                widget: IconButton(
                    onPressed: () => getDateFromUser(),
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey,
                    )),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: InputField(
                        title: 'Start Time',
                        hint: _stratTime,
                        widget: IconButton(
                            onPressed: () => getTimeFromUser(true),
                            icon: const Icon(
                              Icons.access_time,
                              color: Colors.grey,
                            ))),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: InputField(
                        title: 'End Time',
                        hint: _endTime,
                        widget: IconButton(
                            onPressed: () => getTimeFromUser(false),
                            icon: const Icon(
                              Icons.access_time,
                              color: Colors.grey,
                            ))),
                  )
                ],
              ),
              InputField(
                  title: 'Remind',
                  hint: '$_selectedRemind minutes early',
                  widget: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: DropdownButton(
                      dropdownColor: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(10),
                      items: remindList
                          .map(
                            (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  '$value',
                                  style: const TextStyle(color: Colors.white),
                                )),
                          )
                          .toList(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      iconSize: 32,
                      elevation: 4,
                      underline: Container(
                        height: 0,
                      ),
                      onChanged: (int? newval) {
                        setState(() {
                          _selectedRemind = newval!;
                        });
                      },
                      style: subtitleStyle,
                    ),
                  )),
              InputField(
                  title: 'Repeat',
                  hint: _selectedRepeat,
                  widget: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: DropdownButton(
                      dropdownColor: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(10),
                      items: reapeatList
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(color: Colors.white),
                                )),
                          )
                          .toList(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      iconSize: 32,
                      elevation: 4,
                      underline: Container(
                        height: 0,
                      ),
                      onChanged: (String? newval) {
                        setState(() {
                          _selectedRepeat = newval!;
                        });
                      },
                      style: subtitleStyle,
                    ),
                  )),
              const SizedBox(
                height: 18,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  color_bullet(),
                  MyButton(
                      label: 'Create Task',
                      onTab: () {
                        validateDate();
                      })
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: context.theme.backgroundColor,
      leading: ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all(context.theme.backgroundColor)),
          onPressed: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back_ios,
            size: 24,
            color: primaryClr,
          )),
      actions: const [
        CircleAvatar(
          backgroundImage: AssetImage('images/person.jpeg'),
          radius: 18,
        ),
        SizedBox(
          width: 20,
        )
      ],
    );
  }

  addTaskstoDB() async {
    try {
      int value = await _taskController.addTask(
          task: Task(
              title: _titleController.text,
              note: _noteController.text,
              isCompleted: 0,
              date: DateFormat.yMd().format(_selectedDate),
              startTime: _stratTime,
              endTime: _endTime,
              color: selectedcolor,
              remind: _selectedRemind,
              repeat: _selectedRepeat));
      print(value);
    } catch (e) {
      print('Error while adding task to db ');
    }
  }

  validateDate() {
    if (_titleController.text.isNotEmpty && _noteController.text.isNotEmpty) {
      addTaskstoDB();
      Get.back();
    } else if (_titleController.text.isEmpty || _noteController.text.isEmpty) {
      Get.snackbar('required', 'All fields are required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: pinkClr,
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
          ));
    }
  }

  Column color_bullet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: titleStyle,
        ),
        const SizedBox(
          height: 8,
        ),
        Wrap(
            children: List<Widget>.generate(
          3,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                selectedcolor = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                  radius: 14,
                  child: selectedcolor == index
                      ? const Icon(
                          Icons.done,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                  backgroundColor: index == 0
                      ? primaryClr
                      : index == 1
                          ? pinkClr
                          : orangeClr),
            ),
          ),
        ))
      ],
    );
  }

  getDateFromUser() async {
    DateTime? pickeddate = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2015),
        lastDate: DateTime(2030));
    pickeddate != null
        ? setState(() {
            _selectedDate = pickeddate;
          })
        : print('It\'s Null');
  }

  getTimeFromUser(bool isStartTime) async {
    TimeOfDay? pickedtime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? TimeOfDay.fromDateTime(DateTime.now())
          : TimeOfDay.fromDateTime(
              DateTime.now().add(const Duration(minutes: 15))),
    );
    String _formated = pickedtime!.format(context);
    if (isStartTime) {
      setState(() {
        _stratTime = _formated;
      });
    } else if (!isStartTime) {
      setState(() {
        _endTime = _formated;
      });
    } else {
      print('time canceled');
    }
  }
}
