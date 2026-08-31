import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CEOApp());

class Task {
  String title, notes, priority, due;
  bool done;
  Task({required this.title, this.notes='', this.priority='Medium', this.due='', this.done=false});
  Map<String,dynamic> toJson()=>{'title':title,'notes':notes,'priority':priority,'due':due,'done':done};
  factory Task.fromJson(Map<String,dynamic> j)=>Task(title:j['title']??'',notes:j['notes']??'',priority:j['priority']??'Medium',due:j['due']??'',done:j['done']??false);
}

class CEOApp extends StatelessWidget {
  const CEOApp({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'STEMP21 CEO Tasks',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.indigo),
    home:const Dashboard(),
  );
}

class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState()=>_DashboardState(); }

class _DashboardState extends State<Dashboard> {
  List<Task> tasks=[]; bool loading=true;
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final raw=p.getString('tasks');
    if(raw!=null) tasks=(jsonDecode(raw) as List).map((x)=>Task.fromJson(x)).toList();
    setState(()=>loading=false);
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('tasks',jsonEncode(tasks.map((x)=>x.toJson()).toList()));
  }
  int get done=>tasks.where((x)=>x.done).length;
  Future<void> addTask() async {
    final t=await showDialog<Task>(context:context,builder:(_)=>const AddTaskDialog());
    if(t!=null){setState(()=>tasks.add(t));await save();}
  }
  @override Widget build(BuildContext c){
    final pct=tasks.isEmpty?0:done/tasks.length;
    return Scaffold(
      appBar:AppBar(title:const Text('STEMP21 • CEO Daily Tasks'),actions:[IconButton(onPressed:()=>showAboutDialog(context:context,applicationName:'STEMP21 CEO Task Manager'),icon:const Icon(Icons.info_outline))]),
      floatingActionButton:FloatingActionButton.extended(onPressed:addTask,icon:const Icon(Icons.add),label:const Text('Task')),
      body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
        onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
          Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('CEO Dashboard',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
            const SizedBox(height:6),Text(DateTime.now().toLocal().toString().split(' ').first),
            const SizedBox(height:18),LinearProgressIndicator(value:pct),const SizedBox(height:8),
            Text('$done of ${tasks.length} tasks completed • ${(pct*100).round()}%')
          ]))),
          const SizedBox(height:14),
          Row(children:[
            Expanded(child:_stat('Total','${tasks.length}',Icons.list_alt)),
            const SizedBox(width:10),Expanded(child:_stat('Pending','${tasks.length-done}',Icons.pending_actions)),
            const SizedBox(width:10),Expanded(child:_stat('Done','$done',Icons.check_circle))
          ]),
          const SizedBox(height:18),
          const Text('Today',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          if(tasks.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(22),child:Center(child:Text('No tasks yet. Add your first CEO priority.')))),
          ...tasks.asMap().entries.map((e)=>_taskCard(e.key,e.value)),
        ])
      )
    );
  }
  Widget _stat(String a,String b,IconData i)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Icon(i),const SizedBox(height:5),Text(b,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(a)])));
  Widget _taskCard(int i,Task t)=>Card(child:ListTile(
    leading:Checkbox(value:t.done,onChanged:(v)async{setState(()=>t.done=v??false);await save();}),
    title:Text(t.title,style:TextStyle(decoration:t.done?TextDecoration.lineThrough:null,fontWeight:FontWeight.w600)),
    subtitle:Text('${t.priority}${t.due.isEmpty?'':' • ${t.due}'}${t.notes.isEmpty?'':'\n${t.notes}'}'),
    isThreeLine:t.notes.isNotEmpty,
    trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='delete'){setState(()=>tasks.removeAt(i));await save();}},itemBuilder:(_)=>const [PopupMenuItem(value:'delete',child:Text('Delete'))]),
  ));
}

class AddTaskDialog extends StatefulWidget { const AddTaskDialog({super.key}); @override State<AddTaskDialog> createState()=>_AddTaskDialogState(); }
class _AddTaskDialogState extends State<AddTaskDialog>{
  final title=TextEditingController(),notes=TextEditingController(),due=TextEditingController(); String priority='High';
  @override Widget build(BuildContext c)=>AlertDialog(
    title:const Text('Add CEO Task'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'Task title',prefixIcon:Icon(Icons.task_alt))),
      TextField(controller:notes,decoration:const InputDecoration(labelText:'Notes')),
      DropdownButtonFormField<String>(value:priority,decoration:const InputDecoration(labelText:'Priority'),items:['High','Medium','Low'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>priority=x!)),
      TextField(controller:due,decoration:const InputDecoration(labelText:'Due time/date (optional)',prefixIcon:Icon(Icons.schedule))),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()=>title.text.trim().isEmpty?null:Navigator.pop(c,Task(title:title.text.trim(),notes:notes.text.trim(),priority:priority,due:due.text.trim())),child:const Text('Save'))]
  );
}
