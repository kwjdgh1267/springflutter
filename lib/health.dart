import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '헬스 캘린더',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FitnessCalendar(),
    );
  }
}

class FitnessCalendar extends StatefulWidget {
  @override
  _FitnessCalendarState createState() => _FitnessCalendarState();
}

class _FitnessCalendarState extends State<FitnessCalendar> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('헬스 캘린더'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseListScreen(selectedDate: _selectedDate),
                    ),
                  );
                },
                child: Text('날짜 선택'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseListScreen extends StatefulWidget {
  final DateTime selectedDate;
  ExerciseListScreen({required this.selectedDate}) : super();
  @override
  _ExerciseListScreenState createState() => _ExerciseListScreenState();
}
class _ExerciseListScreenState extends State<ExerciseListScreen> {
  TextEditingController searchController = TextEditingController();
  String searchKeyword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운동 등록'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: '운동 검색',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      searchKeyword = searchController.text;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchKeyword = '';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: fetchExercises(searchKeyword),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(snapshot.data![index]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailsScreen(
                                selectedDate: widget.selectedDate,
                                exerciseName: snapshot.data![index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day} 운동 루틴',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: fetchExerciseRecords(widget.selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(snapshot.data![index]),
                        onTap: () {
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}


// 백엔드로부터 해당 날짜에 등록된 운동 기록을 가져오는 함수
Future<List<String>> fetchExerciseRecords(DateTime selectedDate) async {
  final response = await http.get(Uri.parse('http://localhost:8080/record?year=${selectedDate.year}&month=${selectedDate.month}&date=${selectedDate.day}'));
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    List<String> exerciseRecords = List<String>.from(data.map((item) => "${item['exercise']}: ${item['weight'].toString()}kg ${item['count'].toString()}회 x${item['sets'].toString()}세트"));
    return exerciseRecords;
  } else {
    throw Exception('Failed to load exercise records for the selected date');
  }
}

class ExerciseDetailsScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String exerciseName;

  ExerciseDetailsScreen({ required this.selectedDate, required this.exerciseName});

  @override
  _ExerciseDetailsScreenState createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  TextEditingController weightController = TextEditingController();
  TextEditingController repsController = TextEditingController();
  TextEditingController setsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운동 등록'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '운동: ${widget.exerciseName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
            ),
            TextField(
              controller: repsController,
              decoration: InputDecoration(labelText: 'Reps'),
            ),
            TextField(
              controller: setsController,
              decoration: InputDecoration(labelText: 'Sets'),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await submitExerciseData(
                    widget.selectedDate,
                    widget.exerciseName,
                    double.parse(weightController.text),
                    int.parse(repsController.text),
                    int.parse(setsController.text),
                  );

                  // 운동 등록 후 운동 목록 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseListScreen(selectedDate: widget.selectedDate),
                    ),
                  );
                },
                child: Text('등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Backend로부터 운동 목록을 가져오는 함수
Future<List<String>> fetchExercises(String searchKeyword) async {
  final queryParameters = searchKeyword.isNotEmpty ? '?type=$searchKeyword' : '';
  final response = await http.get(Uri.parse('http://localhost:8080/exercise$queryParameters'));
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    List<String> exercises = List<String>.from(data.map((item) => item['title']));
    return exercises;
  } else {
    throw Exception('Failed to load exercises');
  }
}

// 운동 데이터를 서버로 전송하는 함수
Future<void> submitExerciseData(DateTime date, String exerciseName, double weight, int reps, int sets) async {
  final response = await http.post(
    Uri.parse('http://localhost:8080/record'),
    body: jsonEncode({
      'month': date.month,
      'date' : date.day,
      'exercise': exerciseName,
      'weight': weight,
      'count': reps,
      'sets': sets,
      'year': date.year
    }),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to submit exercise data');
  }
}