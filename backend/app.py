from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os

app = Flask(__name__)
# Enable CORS for all routes, allowing requests from any origin (for dev)
CORS(app)

# Database Config (SQLite)
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'wallet_v3.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
# Database reset trigger


db = SQLAlchemy(app)

# --- Models ---

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=True) # Added name field
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    price = db.Column(db.Float, nullable=False)
    description = db.Column(db.String(200))
    type = db.Column(db.String(20), nullable=False, default='expense')
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True) # Linked to User

# --- Routes ---

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Email and password required'}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'User already exists'}), 400

    new_user = User(email=email, name=name)
    new_user.set_password(password)
    
    db.session.add(new_user)
    db.session.commit()

    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()

    if user and user.check_password(password):
        # Return name and id logic
        return jsonify({
            'message': 'Login successful', 
            'user_id': user.id,
            'name': user.name or 'Usuario'
        }), 200
    else:
        return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/products', methods=['GET'])
def get_products():
    user_id = request.args.get('user_id')
    if user_id:
        products = Product.query.filter_by(user_id=user_id).all()
    else:
        # Fallback or global (could limit this in real app)
        products = Product.query.all()
        
    output = []
    for product in products:
        product_data = {
            'id': product.id, 
            'name': product.name, 
            'price': product.price, 
            'description': product.description,
            'type': product.type,
            'user_id': product.user_id
        }
        output.append(product_data)
    return jsonify(output)

@app.route('/api/products', methods=['POST'])
def add_product():
    data = request.get_json()
    name = data.get('name')
    price = data.get('price')
    description = data.get('description', '')
    p_type = data.get('type', 'expense') # Default to expense
    user_id = data.get('user_id') # Expect user_id

    new_product = Product(name=name, price=price, description=description, type=p_type, user_id=user_id)
    db.session.add(new_product)
    db.session.commit()

    return jsonify({'message': 'Product added'}), 201

# --- Init DB ---
with app.app_context():
    db.create_all()
    # No auto-seeding of products now, we want it empty for new users
    
    # Seed default user if needed
    if not User.query.filter_by(email="admin@test.com").first():
        user = User(email="admin@test.com", name="Administrador")
        user.set_password("123456")
        db.session.add(user)
        db.session.commit()

if __name__ == '__main__':
    # Host 0.0.0.0 is important for Android emulator to access (via 10.0.2.2)
    app.run(debug=True, host='0.0.0.0', port=5000)
