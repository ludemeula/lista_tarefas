import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(
        buttonColor: Color(0xff8bf5ff),
        hintColor: Colors.black,
        primaryColor: Color(0xffe0e0e0)),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  final _toDoController = TextEditingController();

  void _addToDo() {
    setState(() {
      Map<String, dynamic> toDo = Map();
      toDo['title'] = _toDoController.text;
      _toDoController.text = '';
      toDo['checked'] = false;
      _toDoList.add(toDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Tarefas',
          //style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Color(0xff0092c4),
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: 'Nova Tarefa',
                        helperText: 'Insira a Nova Tarefa'),
                    style: TextStyle(fontSize: 20),
                    controller: _toDoController,
                  ),
                ),
                RaisedButton(
                  child: Text('ADD'),
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 5),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem),
                  onRefresh: refresh)),
        ],
      ),
    );
  }

  Future<Null> refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if (a['checked'] && !b['checked']) return 1;
        else if (!a['checked'] && b['checked']) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: buildCheckboxListTile(index),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = buildSnackBar();
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Widget buildCheckboxListTile(index) {
    return CheckboxListTile(
      title: Text(_toDoList[index]['title']),
      value: _toDoList[index]['checked'],
      secondary: CircleAvatar(
        child: Icon(_toDoList[index]['checked']
            ? Icons.check_circle
            : Icons.error_outline),
      ),
      onChanged: (check) {
        setState(() {
          _toDoList[index]['checked'] = check;
          _saveData();
        });
      },
    );
  }

  Widget buildSnackBar() {
    return SnackBar(
      content: Text('Tarefa \"${_lastRemoved['title']}\" removida!'),
      action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            setState(() {
              _toDoList.insert(_lastRemovedIndex, _lastRemoved);
              _saveData();
            });
          }),
      duration: Duration(seconds: 2),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
