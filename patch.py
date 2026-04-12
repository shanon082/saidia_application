import os

def patch_chat_page():
    path = 'lib/screens/customers/chatPage.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    s_target = """  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {"""

    s_replace = """  final ScrollController _scrollController = ScrollController();
  String? _fetchedName;

  @override
  void initState() {"""

    content = content.replace(s_target, s_replace)
    
    init_target = """  void initState() {
    super.initState();"""
    init_replace = """  void initState() {
    super.initState();
    _fetchUserName();"""
    content = content.replace(init_target, init_replace)
    
    fetch_func = """  }

  void _sendMessage() {"""
    fetch_func_replace = """  }

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

  void _sendMessage() {"""
    content = content.replace(fetch_func, fetch_func_replace)
    
    name_tx = """Text(
              widget.providerName ?? 'Service Provider',"""
    name_tx_rep = """Text(
              _fetchedName ?? widget.providerName ?? 'Service Provider',"""
    content = content.replace(name_tx, name_tx_rep)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def patch_provider_chat_page():
    path = 'lib/screens/provider/providerChatPage.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    s_target = """  final TextEditingController _messageController = TextEditingController();

  String _formatTime"""
    
    s_replace = """  final TextEditingController _messageController = TextEditingController();
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

  String _formatTime"""
  
    content = content.replace(s_target, s_replace)
    
    name_tx = """title: Text(widget.otherUserName ?? widget.otherUserId),"""
    name_rx = """title: Text(_fetchedName ?? widget.otherUserName ?? widget.otherUserId),"""
    content = content.replace(name_tx, name_rx)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

patch_chat_page()
patch_provider_chat_page()
print("Done")
