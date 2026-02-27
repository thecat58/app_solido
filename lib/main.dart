import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class Producto {
  String nombre;
  String valor;
  String detalle;
  String fechaEntrega;
  String color;
  String? imagen;
  String colorCard;

  Producto({
    required this.nombre,
    required this.valor,
    required this.detalle,
    required this.fechaEntrega,
    required this.color,
    required this.colorCard,
    this.imagen,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'valor': valor,
    'detalle': detalle,
    'fechaEntrega': fechaEntrega,
    'color': color,
    'imagen': imagen,
    'colorCard': colorCard,
  };

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    nombre: json['nombre'],
    valor: json['valor'],
    detalle: json['detalle'],
    fechaEntrega: json['fechaEntrega'],
    color: json['color'],
    imagen: json['imagen'],
    colorCard: json['colorCard'],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ListaProductos(),
    );
  }
}

class ListaProductos extends StatefulWidget {
  const ListaProductos({super.key});

  @override
  State<ListaProductos> createState() => _ListaProductosState();
}

class _ListaProductosState extends State<ListaProductos> {
  List<Producto> productos = [];

  final colores = [
    Color(0xFF00E5FF), // neon cyan
    Color(0xFF00FF94), // neon green
    Color(0xFFFF00E5), // neon pink
    Color(0xFFFFEA00), // neon yellow
    Color(0xFF7C4DFF), // neon purple
    Color(0xFFFF3D00), // neon orange
    Color(0xFF00B0FF), // neon blue
    Color(0xFF1DE9B6),
    Color(0xFFD500F9),
    Color(0xFFFF1744),
    Color(0xFF76FF03),
  ];

  Color colorDesdeString(String c) {
    return Color(int.parse(c));
  }

  String randomColor() {
    final r = Random().nextInt(colores.length);
    return colores[r].value.toString();
  }

  Widget cardProducto(Producto p, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorDesdeString(p.colorCard),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colorDesdeString(p.colorCard).withOpacity(0.7),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          p.imagen != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(p.imagen!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.inventory, size: 40, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "💲${p.valor}",
                  style: const TextStyle(color: Colors.black),
                ),
                Text(
                  "📅 ${p.fechaEntrega}",
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () => abrirModal(producto: p, index: i),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: () => eliminar(i),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> guardar() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = productos.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('productos', data);
  }

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList('productos');

    if (data != null) {
      setState(() {
        productos = data.map((e) => Producto.fromJson(jsonDecode(e))).toList();
      });
    }
  }

  void abrirModal({Producto? producto, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            color: colorDesdeString(producto?.colorCard ?? randomColor()),
            boxShadow: [
              BoxShadow(
                color: colorDesdeString(
                  producto?.colorCard ?? randomColor(),
                ).withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FormProducto(
            producto: producto,
            colorCard: producto?.colorCard ?? randomColor(),
            onGuardar: (p) {
              setState(() {
                if (index != null) {
                  productos[index] = p;
                } else {
                  productos.add(p);
                  listKey.currentState!.insertItem(productos.length - 1);
                }
              });
              guardar();
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  final GlobalKey<AnimatedListState> listKey = GlobalKey();

  void eliminar(int index) {
    final eliminado = productos[index];

    productos.removeAt(index);

    listKey.currentState!.removeItem(
      index,
      (context, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: cardProducto(eliminado, index),
        ),
      ),
      duration: const Duration(milliseconds: 400),
    );

    guardar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos"),
        actions: const [
          Padding(padding: EdgeInsets.all(8), child: Icon(Icons.shopping_bag)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirModal(),
        child: const Icon(Icons.add),
      ),
      body: AnimatedList(
        key: listKey,
        padding: const EdgeInsets.all(10),
        initialItemCount: productos.length,
        itemBuilder: (context, i, animation) {
          final p = productos[i];
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              child: cardProducto(p, i),
            ),
          );
        },
      ),
    );
  }
}

class FormProducto extends StatefulWidget {
  final Producto? producto;
  final String colorCard;
  final Function(Producto) onGuardar;

  const FormProducto({
    super.key,
    this.producto,
    required this.colorCard,
    required this.onGuardar,
  });

  @override
  State<FormProducto> createState() => _FormProductoState();
}

class _FormProductoState extends State<FormProducto> {
  final nombre = TextEditingController();
  final valor = TextEditingController();
  final detalle = TextEditingController();
  final fecha = TextEditingController();
  final color = TextEditingController();
  String? imagen;

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      nombre.text = widget.producto!.nombre;
      valor.text = widget.producto!.valor;
      detalle.text = widget.producto!.detalle;
      fecha.text = widget.producto!.fechaEntrega;
      color.text = widget.producto!.color;
      imagen = widget.producto!.imagen;
    }
  }

  Future<void> seleccionarImagen() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => imagen = img.path);
    }
  }

  void guardar() {
    final p = Producto(
      nombre: nombre.text,
      valor: valor.text,
      detalle: detalle.text,
      fechaEntrega: fecha.text,
      color: color.text,
      imagen: imagen,
      colorCard: widget.colorCard,
    );
    widget.onGuardar(p);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 15,
        right: 15,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Nuevo Pedido",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nombre,
              decoration: const InputDecoration(labelText: "Producto"),
            ),
            TextField(
              controller: valor,
              decoration: const InputDecoration(labelText: "Valor"),
            ),
            TextField(
              controller: detalle,
              decoration: const InputDecoration(labelText: "Detalle"),
            ),
            TextField(
              controller: fecha,
              decoration: const InputDecoration(labelText: "Entrega"),
            ),
            TextField(
              controller: color,
              decoration: const InputDecoration(labelText: "Color real"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: seleccionarImagen,
              child: const Text("Imagen"),
            ),
            if (imagen != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Image.file(File(imagen!), height: 80),
              ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: guardar, child: const Text("Guardar")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
