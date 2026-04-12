import 'dart:io';

void patchChatPage() {
  final path = 'lib/screens/customers/chatPage.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  final sTarget = '''  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {''';
  final sReplace = '''  final ScrollController _scrollController = ScrollController();
  String? _fetchedName;

  @override
  void initState() {''';
  content = content.replaceAll(sTarget, sReplace);

  final initTarget = '''  void initState() {
    super.initState();''';
  final initReplace = '''  void initState() {
    super.initState();
    _fetchUserName();''';
  content = content.replaceAll(initTarget, initReplace);

  final fetchFunc = '''  }

  void _sendMessage() {''';
  final fetchFuncReplace = '''  }

  Future<void> _fetchUserName() async {
    if (widget.providerName != null && widget.providerName!.isNotEmpty) {
      _fetchedName = widget.providerName;
      setState((){});
      return;
    }
    try {
      final res = await Supabase.instance.client.from('users').select('name').eq('id', widget.providerId).maybeSingle();
      if (res != null) {
        setState(() => _fetchedName = res['name']);
      }
    } catch (_) {}
  }

  void _sendMessage() {''';
  content = content.replaceAll(fetchFunc, fetchFuncReplace);

  final nameTx = '''Text(
              widget.providerName ?? 'Service Provider',''';
  final nameTxRep = '''Text(
              _fetchedName ?? widget.providerName ?? 'Service Provider',''';
  content = content.replaceAll(nameTx, nameTxRep);

  file.writeAsStringSync(content);
}

void patchProviderChatPage() {
  final path = 'lib/screens/provider/providerChatPage.dart';
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  final sTarget = '''  final TextEditingController _messageController = TextEditingController();

  String _formatTime''';
  final sReplace = '''  final TextEditingController _messageController = TextEditingController();
  String? _fetchedName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (widget.otherUserName != null && widget.otherUserName!.isNotEmpty) {
      _fetchedName = widget.otherUserName;
      setState((){});
      return;
    }
    try {
      final res = await Supabase.instance.client.from('users').select('name').eq('id', widget.otherUserId).maybeSingle();
      if (res != null) {
        setState(() => _fetchedName = res['name']);
      }
    } catch (_) {}
  }

  String _formatTime''';
  content = content.replaceAll(sTarget, sReplace);

  final nameTx = '''title: Text(widget.otherUserName ?? widget.otherUserId),''';
  final nameRx = '''title: Text(_fetchedName ?? widget.otherUserName ?? widget.otherUserId),''';
  content = content.replaceAll(nameTx, nameRx);

  file.writeAsStringSync(content);
}

void main() {
  patchChatPage();
  patchProviderChatPage();
  print("Done");
}
