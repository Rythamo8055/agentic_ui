// Forui Widget Catalog for GenUI
// Custom CatalogItems wrapping Forui components

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

// ============================================================================
// FORUI BUTTON
// ============================================================================

final _fButtonSchema = dsb.S.object(
  properties: {
    'label': A2uiSchemas.stringReference(description: 'Button label text'),
    'style': dsb.S.string(
      description: 'Button style: primary, secondary, outline, destructive',
    ),
    'action': A2uiSchemas.action(description: 'Action when button is pressed'),
  },
  required: ['label', 'action'],
);

extension type _FButtonData.fromMap(Map<String, Object?> _json) {
  JsonMap get label => _json['label'] as JsonMap;
  String? get style => _json['style'] as String?;
  JsonMap get action => _json['action'] as JsonMap;
}

final foruiButton = CatalogItem(
  name: 'ForuiButton',
  dataSchema: _fButtonSchema,
  exampleData: [
    () => '''
    [{"id": "btn1", "component": {"ForuiButton": {"label": {"literalString": "Submit"}, "style": "primary", "action": {"name": "submit"}}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _FButtonData.fromMap(itemContext.data as Map<String, Object?>);
    final labelNotifier = itemContext.dataContext.subscribeToString(data.label);

    return ValueListenableBuilder<String?>(
      valueListenable: labelNotifier,
      builder: (context, label, _) {
        return FButton(
          onPress: () => _dispatchAction(itemContext, data.action),
          child: Text(label ?? 'Button'),
        );
      },
    );
  },
);

// ============================================================================
// FORUI CARD
// ============================================================================

final _fCardSchema = dsb.S.object(
  properties: {
    'title': A2uiSchemas.stringReference(description: 'Card title'),
    'subtitle': A2uiSchemas.stringReference(description: 'Card subtitle'),
    'child': dsb.S.string(description: 'Child widget ID'),
  },
);

extension type _FCardData.fromMap(Map<String, Object?> _json) {
  JsonMap? get title => _json['title'] as JsonMap?;
  JsonMap? get subtitle => _json['subtitle'] as JsonMap?;
  String? get child => _json['child'] as String?;
}

final foruiCard = CatalogItem(
  name: 'ForuiCard',
  dataSchema: _fCardSchema,
  exampleData: [
    () => '''
    [{"id": "card1", "component": {"ForuiCard": {"title": {"literalString": "Lesson 1"}, "subtitle": {"literalString": "Introduction"}}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _FCardData.fromMap(itemContext.data as Map<String, Object?>);
    
    Widget? titleWidget;
    if (data.title != null) {
      final titleNotifier = itemContext.dataContext.subscribeToString(data.title!);
      titleWidget = ValueListenableBuilder<String?>(
        valueListenable: titleNotifier,
        builder: (_, title, __) => Text(
          title ?? '', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }

    Widget? subtitleWidget;
    if (data.subtitle != null) {
      final subtitleNotifier = itemContext.dataContext.subscribeToString(data.subtitle!);
      subtitleWidget = ValueListenableBuilder<String?>(
        valueListenable: subtitleNotifier,
        builder: (_, subtitle, __) => Text(
          subtitle ?? '', 
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    Widget? childWidget;
    if (data.child != null) {
      childWidget = itemContext.buildChild(data.child!);
    }

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleWidget != null) titleWidget,
          if (subtitleWidget != null) ...[const SizedBox(height: 4), subtitleWidget],
          if (childWidget != null) ...[const SizedBox(height: 12), childWidget],
        ],
      ),
    );
  },
);

// ============================================================================
// FORUI ALERT
// ============================================================================

final _fAlertSchema = dsb.S.object(
  properties: {
    'title': A2uiSchemas.stringReference(description: 'Alert title'),
    'message': A2uiSchemas.stringReference(description: 'Alert message'),
    'isDestructive': dsb.S.boolean(description: 'If true, shows error style'),
  },
  required: ['title', 'message'],
);

extension type _FAlertData.fromMap(Map<String, Object?> _json) {
  JsonMap get title => _json['title'] as JsonMap;
  JsonMap get message => _json['message'] as JsonMap;
  bool get isDestructive => _json['isDestructive'] as bool? ?? false;
}

final foruiAlert = CatalogItem(
  name: 'ForuiAlert',
  dataSchema: _fAlertSchema,
  exampleData: [
    () => '''
    [{"id": "alert1", "component": {"ForuiAlert": {"title": {"literalString": "Great job!"}, "message": {"literalString": "You got the answer correct!"}}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _FAlertData.fromMap(itemContext.data as Map<String, Object?>);
    final titleNotifier = itemContext.dataContext.subscribeToString(data.title);
    final messageNotifier = itemContext.dataContext.subscribeToString(data.message);

    return ValueListenableBuilder<String?>(
      valueListenable: titleNotifier,
      builder: (context, title, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: messageNotifier,
          builder: (context, message, _) {
            return FAlert(
              icon: Icon(data.isDestructive ? FIcons.triangleAlert : FIcons.circleCheck),
              title: Text(title ?? ''),
              subtitle: Text(message ?? ''),
            );
          },
        );
      },
    );
  },
);

// ============================================================================
// FORUI PROGRESS
// ============================================================================

final _fProgressSchema = dsb.S.object(
  properties: {
    'value': dsb.S.number(description: 'Progress value 0.0 to 1.0'),
  },
  required: ['value'],
);

final foruiProgress = CatalogItem(
  name: 'ForuiProgress',
  dataSchema: _fProgressSchema,
  exampleData: [
    () => '''
    [{"id": "progress1", "component": {"ForuiProgress": {"value": 0.75}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final value = (data['value'] as num?)?.toDouble() ?? 0.0;
    return LinearProgressIndicator(value: value);
  },
);

// ============================================================================
// FORUI BADGE
// ============================================================================

final _fBadgeSchema = dsb.S.object(
  properties: {
    'label': A2uiSchemas.stringReference(description: 'Badge label'),
    'style': dsb.S.string(description: 'Badge style: primary, secondary, outline, destructive'),
  },
  required: ['label'],
);

extension type _FBadgeData.fromMap(Map<String, Object?> _json) {
  JsonMap get label => _json['label'] as JsonMap;
  String? get style => _json['style'] as String?;
}

final foruiBadge = CatalogItem(
  name: 'ForuiBadge',
  dataSchema: _fBadgeSchema,
  exampleData: [
    () => '''
    [{"id": "badge1", "component": {"ForuiBadge": {"label": {"literalString": "New"}, "style": "primary"}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = _FBadgeData.fromMap(itemContext.data as Map<String, Object?>);
    final labelNotifier = itemContext.dataContext.subscribeToString(data.label);

    return ValueListenableBuilder<String?>(
      valueListenable: labelNotifier,
      builder: (context, label, _) {
        return FBadge(
          child: Text(label ?? ''),
        );
      },
    );
  },
);

// ============================================================================
// FORUI DIVIDER
// ============================================================================

final _fDividerSchema = dsb.S.object(
  properties: {
    'vertical': dsb.S.boolean(description: 'If true, divider is vertical'),
  },
);

final foruiDivider = CatalogItem(
  name: 'ForuiDivider',
  dataSchema: _fDividerSchema,
  exampleData: [
    () => '''
    [{"id": "divider1", "component": {"ForuiDivider": {}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final vertical = data['vertical'] as bool? ?? false;
    return vertical ? const FDivider(axis: Axis.vertical) : const FDivider();
  },
);

// ============================================================================
// FORUI ACCORDION
// ============================================================================

final _fAccordionSchema = dsb.S.object(
  properties: {
    'items': dsb.S.list(
      description: 'List of accordion items',
      items: dsb.S.object(
        properties: {
          'title': dsb.S.string(description: 'Item title'),
          'content': dsb.S.string(description: 'Item content'),
        },
        required: ['title', 'content'],
      ),
    ),
  },
  required: ['items'],
);

final foruiAccordion = CatalogItem(
  name: 'ForuiAccordion',
  dataSchema: _fAccordionSchema,
  exampleData: [
    () => '''
    [{"id": "accordion1", "component": {"ForuiAccordion": {"items": [
      {"title": "What is Flutter?", "content": "Flutter is a UI toolkit."},
      {"title": "What is Dart?", "content": "Dart is a programming language."}
    ]}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final items = (data['items'] as List?)?.cast<Map<String, Object?>>() ?? [];
    
    return FAccordion(
      children: items.map((item) {
        final title = item['title'] as String? ?? '';
        final content = item['content'] as String? ?? '';
        
        return FAccordionItem(
          title: Text(title),
          child: Text(content),
        );
      }).toList(),
    );
  },
);

// ============================================================================
// FORUI AVATAR
// ============================================================================

final _fAvatarSchema = dsb.S.object(
  properties: {
    'imageUrl': dsb.S.string(description: 'Avatar image URL'),
    'fallback': dsb.S.string(description: 'Fallback text (initials)'),
  },
);

final foruiAvatar = CatalogItem(
  name: 'ForuiAvatar',
  dataSchema: _fAvatarSchema,
  exampleData: [
    () => '''
    [{"id": "avatar1", "component": {"ForuiAvatar": {"fallback": "JD"}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final fallbackText = data['fallback'] as String? ?? 'U';
    final imageUrl = data['imageUrl'] as String?;

    return FAvatar(
      image: imageUrl != null ? NetworkImage(imageUrl) : const AssetImage('assets/placeholder.png'),
      fallback: Text(fallbackText),
    );
  },
);

// ============================================================================
// FORUI SWITCH
// ============================================================================

final _fSwitchSchema = dsb.S.object(
  properties: {
    'value': dsb.S.boolean(description: 'Switch value (on/off)'),
    'label': dsb.S.string(description: 'Switch label'),
  },
);

final foruiSwitch = CatalogItem(
  name: 'ForuiSwitch',
  dataSchema: _fSwitchSchema,
  exampleData: [
    () => '''
    [{"id": "switch1", "component": {"ForuiSwitch": {"value": false, "label": "Dark Mode"}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final value = data['value'] as bool? ?? false;
    final label = data['label'] as String?;

    Widget switchWidget = FSwitch(
      value: value,
      onChange: (_) {},  // Read-only for now
    );

    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          switchWidget,
        ],
      );
    }

    return switchWidget;
  },
);

// ============================================================================
// FORUI CHECKBOX
// ============================================================================

final _fCheckboxSchema = dsb.S.object(
  properties: {
    'value': dsb.S.boolean(description: 'Checkbox checked state'),
    'label': dsb.S.string(description: 'Checkbox label'),
  },
);

final foruiCheckbox = CatalogItem(
  name: 'ForuiCheckbox',
  dataSchema: _fCheckboxSchema,
  exampleData: [
    () => '''
    [{"id": "checkbox1", "component": {"ForuiCheckbox": {"value": false, "label": "Option A"}}}]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final value = data['value'] as bool? ?? false;
    final label = data['label'] as String?;

    return FCheckbox(
      value: value,
      label: label != null ? Text(label) : null,
      onChange: (_) {},  // Read-only for now
    );
  },
);

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

void _dispatchAction(CatalogItemContext itemContext, JsonMap action) {
  final name = action['name'] as String;
  final List<Object?> contextDef = (action['context'] as List<Object?>?) ?? [];
  final resolvedContext = resolveContext(itemContext.dataContext, contextDef);
  
  itemContext.dispatchEvent(
    UserActionEvent(
      name: name,
      sourceComponentId: itemContext.id,
      context: resolvedContext,
    ),
  );
}

// ============================================================================
// FORUI CATALOG - COMBINE ALL WIDGETS
// ============================================================================

/// The complete Forui catalog for GenUI
final foruiCatalog = Catalog([
  // Core layout (from GenUI)
  CoreCatalogItems.column,
  CoreCatalogItems.row,
  CoreCatalogItems.text,
  CoreCatalogItems.list,
  
  // Forui components
  foruiButton,
  foruiCard,
  foruiAlert,
  foruiProgress,
  foruiBadge,
  foruiDivider,
  foruiAccordion,
  foruiAvatar,
  foruiSwitch,
  foruiCheckbox,
], catalogId: 'forui_learning_v1');
