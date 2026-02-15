"""Seed database with 20 categories and 10 products per category with attractive images."""
import asyncio
import uuid
from datetime import datetime, timezone
from sqlalchemy import text
from app.database import engine, AsyncSessionLocal, Base
from app.models.product import ProductCategory, Product, ProductImage, ProductStatus, UnitType
from app.models.vendor import Vendor, VendorStatus
from app.models.user import User, UserRole
import bcrypt
import re

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def _product_slug(name: str) -> str:
    """Convert product name to its local image asset slug."""
    s = name.lower().replace(" ", "-").replace("(", "").replace(")", "").replace("&", "and")
    return re.sub(r'-+', '-', s).strip('-')

# ─── High-quality Unsplash/Pexels image URLs for categories ───
CATEGORIES = [
    {
        "name": "Fresh Fruits",
        "slug": "fresh-fruits",
        "description": "Handpicked seasonal fruits delivered fresh to your doorstep",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/415/415682.png",
        "image_url": "https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600&q=80",
        "sort_order": 1,
    },
    {
        "name": "Fresh Vegetables",
        "slug": "fresh-vegetables",
        "description": "Farm-fresh vegetables picked daily for your kitchen",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2153/2153786.png",
        "image_url": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80",
        "sort_order": 2,
    },
    {
        "name": "Dairy & Eggs",
        "slug": "dairy-eggs",
        "description": "Fresh milk, cheese, butter, yogurt and farm eggs",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/3050/3050158.png",
        "image_url": "https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=600&q=80",
        "sort_order": 3,
    },
    {
        "name": "Bakery & Bread",
        "slug": "bakery-bread",
        "description": "Freshly baked bread, cakes, pastries and more",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/3081/3081967.png",
        "image_url": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80",
        "sort_order": 4,
    },
    {
        "name": "Meat & Poultry",
        "slug": "meat-poultry",
        "description": "Premium quality fresh meat and poultry products",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/1046/1046751.png",
        "image_url": "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=600&q=80",
        "sort_order": 5,
    },
    {
        "name": "Seafood & Fish",
        "slug": "seafood-fish",
        "description": "Fresh catch of the day — fish, shrimp, and more",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2838/2838016.png",
        "image_url": "https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=600&q=80",
        "sort_order": 6,
    },
    {
        "name": "Beverages",
        "slug": "beverages",
        "description": "Juices, sodas, coffee, tea and refreshing drinks",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2405/2405479.png",
        "image_url": "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=600&q=80",
        "sort_order": 7,
    },
    {
        "name": "Snacks & Chips",
        "slug": "snacks-chips",
        "description": "Crunchy snacks, chips, nuts and munchies",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2553/2553691.png",
        "image_url": "https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=600&q=80",
        "sort_order": 8,
    },
    {
        "name": "Frozen Foods",
        "slug": "frozen-foods",
        "description": "Frozen meals, ice cream, vegetables and ready-to-eat",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2965/2965567.png",
        "image_url": "https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=600&q=80",
        "sort_order": 9,
    },
    {
        "name": "Rice & Grains",
        "slug": "rice-grains",
        "description": "Premium rice varieties, quinoa, oats and cereals",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/3174/3174880.png",
        "image_url": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&q=80",
        "sort_order": 10,
    },
    {
        "name": "Spices & Herbs",
        "slug": "spices-herbs",
        "description": "Aromatic spices and fresh herbs for every recipe",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2674/2674505.png",
        "image_url": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80",
        "sort_order": 11,
    },
    {
        "name": "Cooking Oil & Ghee",
        "slug": "cooking-oil-ghee",
        "description": "Pure cooking oils, olive oil, ghee and butter",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/5787/5787016.png",
        "image_url": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&q=80",
        "sort_order": 12,
    },
    {
        "name": "Pasta & Noodles",
        "slug": "pasta-noodles",
        "description": "Italian pasta, Asian noodles and instant meals",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/1471/1471262.png",
        "image_url": "https://images.unsplash.com/photo-1551462147-37885acc36f1?w=600&q=80",
        "sort_order": 13,
    },
    {
        "name": "Sauces & Condiments",
        "slug": "sauces-condiments",
        "description": "Ketchup, mayo, soy sauce and gourmet dressings",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2515/2515183.png",
        "image_url": "https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=600&q=80",
        "sort_order": 14,
    },
    {
        "name": "Organic & Health",
        "slug": "organic-health",
        "description": "Certified organic products and health supplements",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2909/2909765.png",
        "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=80",
        "sort_order": 15,
    },
    {
        "name": "Baby Care",
        "slug": "baby-care",
        "description": "Baby food, formula, diapers and essentials",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/3373/3373060.png",
        "image_url": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=600&q=80",
        "sort_order": 16,
    },
    {
        "name": "Personal Care",
        "slug": "personal-care",
        "description": "Soaps, shampoos, skincare and personal hygiene",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2553/2553642.png",
        "image_url": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=600&q=80",
        "sort_order": 17,
    },
    {
        "name": "Household & Cleaning",
        "slug": "household-cleaning",
        "description": "Detergents, cleaners, tissues and home essentials",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/995/995053.png",
        "image_url": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=600&q=80",
        "sort_order": 18,
    },
    {
        "name": "Chocolates & Sweets",
        "slug": "chocolates-sweets",
        "description": "Premium chocolates, candies and traditional sweets",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/3081/3081906.png",
        "image_url": "https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=600&q=80",
        "sort_order": 19,
    },
    {
        "name": "Pet Supplies",
        "slug": "pet-supplies",
        "description": "Food, treats and accessories for your furry friends",
        "icon_url": "https://cdn-icons-png.flaticon.com/128/2171/2171991.png",
        "image_url": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600&q=80",
        "sort_order": 20,
    },
]

# ─── Products per category with real Unsplash images ───
PRODUCTS_BY_CATEGORY = {
    "fresh-fruits": [
        {"name": "Red Apple", "price": 3.49, "compare_at_price": 4.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "is_organic": True, "stock_quantity": 200, "description": "Crisp, sweet and juicy red apples from the orchards of Washington.", "image": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&q=80"},
        {"name": "Banana", "price": 1.29, "compare_at_price": 1.99, "unit_type": "dozen", "unit_value": 1, "is_featured": True, "stock_quantity": 350, "description": "Perfectly ripe yellow bananas, rich in potassium.", "image": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80"},
        {"name": "Fresh Strawberry", "price": 5.99, "compare_at_price": 7.99, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 100, "description": "Sweet, juicy strawberries picked at peak ripeness.", "image": "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=400&q=80"},
        {"name": "Orange", "price": 2.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 180, "description": "Navel oranges bursting with citrus flavor and vitamin C.", "image": "https://images.unsplash.com/photo-1547514701-42782101795e?w=400&q=80"},
        {"name": "Mango", "price": 4.99, "compare_at_price": 6.49, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 120, "description": "Alphonso mangoes — the king of fruits, sweet and aromatic.", "image": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=400&q=80"},
        {"name": "Blueberry Pack", "price": 6.49, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 90, "description": "Organic blueberries packed with antioxidants.", "image": "https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=400&q=80"},
        {"name": "Green Grapes", "price": 3.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 150, "description": "Seedless green grapes, crisp and refreshing.", "image": "https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=400&q=80"},
        {"name": "Watermelon", "price": 7.99, "unit_type": "piece", "unit_value": 1, "is_featured": True, "stock_quantity": 60, "description": "Large, sweet watermelon perfect for summer.", "image": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80"},
        {"name": "Pineapple", "price": 3.49, "unit_type": "piece", "unit_value": 1, "stock_quantity": 80, "description": "Golden pineapple with tropical sweetness.", "image": "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=400&q=80"},
        {"name": "Kiwi", "price": 4.29, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 100, "description": "Tangy New Zealand kiwis rich in vitamin C.", "image": "https://images.unsplash.com/photo-1585059895524-72e550cfc79d?w=400&q=80"},
    ],
    "fresh-vegetables": [
        {"name": "Broccoli", "price": 2.49, "unit_type": "piece", "unit_value": 1, "is_organic": True, "stock_quantity": 150, "description": "Fresh organic broccoli, packed with nutrients.", "image": "https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=400&q=80"},
        {"name": "Tomatoes", "price": 1.99, "compare_at_price": 2.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 300, "description": "Vine-ripened red tomatoes, juicy and flavorful.", "image": "https://images.unsplash.com/photo-1546470427-0d4db154ceb8?w=400&q=80"},
        {"name": "Spinach Bundle", "price": 1.49, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 200, "description": "Fresh baby spinach leaves, perfect for salads.", "image": "https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&q=80"},
        {"name": "Bell Peppers", "price": 3.49, "unit_type": "kg", "unit_value": 1, "stock_quantity": 180, "description": "Colorful mix of red, yellow and green bell peppers.", "image": "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400&q=80"},
        {"name": "Carrots", "price": 1.79, "unit_type": "kg", "unit_value": 1, "stock_quantity": 250, "description": "Crunchy orange carrots, great for cooking and snacking.", "image": "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&q=80"},
        {"name": "Cucumber", "price": 0.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 300, "description": "Cool and crisp English cucumbers.", "image": "https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&q=80"},
        {"name": "Onions", "price": 1.29, "unit_type": "kg", "unit_value": 1, "stock_quantity": 400, "description": "Fresh yellow onions, essential for every kitchen.", "image": "https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400&q=80"},
        {"name": "Potatoes", "price": 1.49, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 500, "description": "Russet potatoes perfect for baking, frying or mashing.", "image": "https://images.unsplash.com/photo-1518977676601-b53f82ber633?w=400&q=80"},
        {"name": "Avocado", "price": 2.99, "compare_at_price": 3.99, "unit_type": "piece", "unit_value": 1, "is_featured": True, "stock_quantity": 120, "description": "Creamy Hass avocados, perfectly ripe.", "image": "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400&q=80"},
        {"name": "Sweet Corn", "price": 1.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 200, "description": "Yellow sweet corn on the cob, tender and sweet.", "image": "https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400&q=80"},
    ],
    "dairy-eggs": [
        {"name": "Whole Milk", "price": 3.49, "unit_type": "litre", "unit_value": 1, "is_featured": True, "stock_quantity": 200, "description": "Farm fresh whole milk, pasteurized and creamy.", "image": "https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&q=80"},
        {"name": "Greek Yogurt", "price": 4.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 150, "description": "Thick and creamy Greek yogurt, high in protein.", "image": "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&q=80"},
        {"name": "Farm Eggs (12)", "price": 5.49, "compare_at_price": 6.99, "unit_type": "dozen", "unit_value": 1, "is_featured": True, "stock_quantity": 180, "description": "Free-range farm eggs from happy hens.", "image": "https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400&q=80"},
        {"name": "Cheddar Cheese", "price": 6.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Aged sharp cheddar cheese, rich and flavorful.", "image": "https://images.unsplash.com/photo-1618164436241-4473940d1f5c?w=400&q=80"},
        {"name": "Butter (Unsalted)", "price": 4.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 120, "description": "Pure unsalted butter for baking and cooking.", "image": "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400&q=80"},
        {"name": "Mozzarella", "price": 5.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 90, "description": "Fresh mozzarella cheese, perfect for pizza and salads.", "image": "https://images.unsplash.com/photo-1626957341926-98752fc2ba90?w=400&q=80"},
        {"name": "Heavy Cream", "price": 3.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 80, "description": "Rich heavy whipping cream for desserts and sauces.", "image": "https://images.unsplash.com/photo-1587657472852-16caaf1d0f22?w=400&q=80"},
        {"name": "Cottage Cheese", "price": 3.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 110, "description": "Low-fat cottage cheese, great for healthy meals.", "image": "https://images.unsplash.com/photo-1559561853-08451507cbe7?w=400&q=80"},
        {"name": "Almond Milk", "price": 4.29, "compare_at_price": 5.49, "unit_type": "litre", "unit_value": 1, "stock_quantity": 130, "description": "Unsweetened almond milk, dairy-free alternative.", "image": "https://images.unsplash.com/photo-1600788886242-5c96aabe3757?w=400&q=80"},
        {"name": "Paneer", "price": 5.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Fresh Indian cottage cheese (paneer), soft and tasty.", "image": "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&q=80"},
    ],
    "bakery-bread": [
        {"name": "Sourdough Bread", "price": 4.99, "unit_type": "piece", "unit_value": 1, "is_featured": True, "stock_quantity": 80, "description": "Artisanal sourdough bread with a crusty exterior.", "image": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80"},
        {"name": "Whole Wheat Bread", "price": 3.49, "unit_type": "piece", "unit_value": 1, "stock_quantity": 120, "description": "100% whole wheat bread, wholesome and hearty.", "image": "https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=400&q=80"},
        {"name": "Croissant (4 pack)", "price": 5.99, "compare_at_price": 7.49, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 60, "description": "Buttery, flaky French croissants.", "image": "https://images.unsplash.com/photo-1555507036-ab1f4038024a?w=400&q=80"},
        {"name": "Bagels (6 pack)", "price": 4.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 70, "description": "Chewy New York-style bagels, freshly baked.", "image": "https://images.unsplash.com/photo-1585535958672-2263af2b315c?w=400&q=80"},
        {"name": "Chocolate Muffin", "price": 2.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 90, "description": "Rich chocolate chip muffin with gooey center.", "image": "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400&q=80"},
        {"name": "Baguette", "price": 2.49, "unit_type": "piece", "unit_value": 1, "stock_quantity": 100, "description": "Classic French baguette with crispy crust.", "image": "https://images.unsplash.com/photo-1549931319-a545753d62ce?w=400&q=80"},
        {"name": "Cinnamon Roll", "price": 3.49, "unit_type": "piece", "unit_value": 1, "is_featured": True, "stock_quantity": 75, "description": "Soft, sweet cinnamon rolls with cream cheese icing.", "image": "https://images.unsplash.com/photo-1509365390695-33aee754301f?w=400&q=80"},
        {"name": "Focaccia", "price": 5.49, "unit_type": "piece", "unit_value": 1, "stock_quantity": 50, "description": "Italian herb focaccia bread with rosemary and olive oil.", "image": "https://images.unsplash.com/photo-1573140401552-3fab0b24306f?w=400&q=80"},
        {"name": "Danish Pastry", "price": 3.29, "unit_type": "piece", "unit_value": 1, "stock_quantity": 65, "description": "Fruit-filled Danish pastry with flaky layers.", "image": "https://images.unsplash.com/photo-1612240498936-65f5101365d2?w=400&q=80"},
        {"name": "Garlic Bread", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 85, "description": "Crispy garlic bread with herbs, ready to bake.", "image": "https://images.unsplash.com/photo-1619535860434-ba1d8fa12536?w=400&q=80"},
    ],
    "meat-poultry": [
        {"name": "Chicken Breast", "price": 8.99, "compare_at_price": 10.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 150, "description": "Boneless skinless chicken breast, tender and lean.", "image": "https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400&q=80"},
        {"name": "Ground Beef", "price": 9.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 120, "description": "Premium 80/20 ground beef, perfect for burgers.", "image": "https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=400&q=80"},
        {"name": "Lamb Chops", "price": 14.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 60, "description": "Tender lamb chops, ideal for grilling and roasting.", "image": "https://images.unsplash.com/photo-1603048297172-c92544798d5a?w=400&q=80"},
        {"name": "Whole Chicken", "price": 7.49, "compare_at_price": 9.99, "unit_type": "piece", "unit_value": 1, "is_featured": True, "stock_quantity": 80, "description": "Farm-raised whole chicken, ready for roasting.", "image": "https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=400&q=80"},
        {"name": "Turkey Breast", "price": 11.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 50, "description": "Lean turkey breast, great for sandwiches.", "image": "https://images.unsplash.com/photo-1574672280600-4accfa5b6f98?w=400&q=80"},
        {"name": "Pork Tenderloin", "price": 10.49, "unit_type": "kg", "unit_value": 1, "stock_quantity": 70, "description": "Juicy pork tenderloin, versatile and delicious.", "image": "https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=400&q=80"},
        {"name": "Chicken Wings", "price": 6.99, "compare_at_price": 8.49, "unit_type": "kg", "unit_value": 1, "stock_quantity": 130, "description": "Fresh chicken wings, perfect for game day.", "image": "https://images.unsplash.com/photo-1527477396000-e27163b4bcd1?w=400&q=80"},
        {"name": "Beef Steak Ribeye", "price": 18.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 40, "description": "USDA Choice ribeye steak, beautifully marbled.", "image": "https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400&q=80"},
        {"name": "Sausages (6 pack)", "price": 7.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 90, "description": "Gourmet pork sausages with Italian herbs.", "image": "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&q=80"},
        {"name": "Duck Breast", "price": 16.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 30, "description": "Premium duck breast for fine dining at home.", "image": "https://images.unsplash.com/photo-1606728035253-49e8a23146de?w=400&q=80"},
    ],
    "seafood-fish": [
        {"name": "Atlantic Salmon", "price": 12.99, "compare_at_price": 15.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 80, "description": "Fresh Atlantic salmon fillet, rich in omega-3.", "image": "https://images.unsplash.com/photo-1499125562588-29fb8a56b5d5?w=400&q=80"},
        {"name": "Jumbo Shrimp", "price": 14.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 60, "description": "Large peeled and deveined jumbo shrimp.", "image": "https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400&q=80"},
        {"name": "Tuna Steak", "price": 16.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 40, "description": "Sushi-grade yellowfin tuna steak.", "image": "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&q=80"},
        {"name": "Cod Fillet", "price": 10.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 70, "description": "Mild and flaky Atlantic cod fillet.", "image": "https://images.unsplash.com/photo-1510130113581-82a1e1e50588?w=400&q=80"},
        {"name": "Crab Meat", "price": 19.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 30, "description": "Premium lump crab meat, ready to eat.", "image": "https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=400&q=80"},
        {"name": "Mussels", "price": 8.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 50, "description": "Fresh blue mussels, great for steaming.", "image": "https://images.unsplash.com/photo-1559742811-822babe4afb6?w=400&q=80"},
        {"name": "Tilapia Fillet", "price": 7.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 90, "description": "Light and mild tilapia fillets.", "image": "https://images.unsplash.com/photo-1535140728325-a4d3707eee61?w=400&q=80"},
        {"name": "Lobster Tail", "price": 24.99, "compare_at_price": 29.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 20, "description": "Succulent lobster tail for a special dinner.", "image": "https://images.unsplash.com/photo-1559564484-e48b3e040ff4?w=400&q=80"},
        {"name": "Sardines", "price": 4.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 120, "description": "Packed sardines in olive oil, high in omega-3.", "image": "https://images.unsplash.com/photo-1599084993091-1cb5c0721cc6?w=400&q=80"},
        {"name": "Squid Rings", "price": 9.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 55, "description": "Tender squid rings, perfect for frying.", "image": "https://images.unsplash.com/photo-1603073163308-9654c3fb70b5?w=400&q=80"},
    ],
    "beverages": [
        {"name": "Orange Juice", "price": 4.49, "compare_at_price": 5.99, "unit_type": "litre", "unit_value": 1, "is_featured": True, "stock_quantity": 180, "description": "Freshly squeezed orange juice, not from concentrate.", "image": "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80"},
        {"name": "Green Tea (20 bags)", "price": 3.99, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 200, "description": "Japanese organic green tea bags for daily wellness.", "image": "https://images.unsplash.com/photo-1556881286-fc6915169721?w=400&q=80"},
        {"name": "Ground Coffee", "price": 8.99, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 150, "description": "Colombian medium roast ground coffee, bold and smooth.", "image": "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&q=80"},
        {"name": "Coconut Water", "price": 2.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 220, "description": "Pure coconut water, natural electrolyte drink.", "image": "https://images.unsplash.com/photo-1585238342024-78d387f4132e?w=400&q=80"},
        {"name": "Sparkling Water", "price": 1.99, "unit_type": "litre", "unit_value": 1, "stock_quantity": 300, "description": "Naturally carbonated sparkling mineral water.", "image": "https://images.unsplash.com/photo-1606168094336-48f205276929?w=400&q=80"},
        {"name": "Protein Smoothie", "price": 5.49, "unit_type": "ml", "unit_value": 350, "stock_quantity": 80, "description": "Mixed berry protein smoothie, ready to drink.", "image": "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&q=80"},
        {"name": "Apple Cider", "price": 6.49, "unit_type": "litre", "unit_value": 1, "is_organic": True, "stock_quantity": 70, "description": "Organic raw apple cider vinegar with the mother.", "image": "https://images.unsplash.com/photo-1576673442511-7e39b6545c87?w=400&q=80"},
        {"name": "Iced Tea Lemon", "price": 2.49, "unit_type": "ml", "unit_value": 500, "stock_quantity": 200, "description": "Refreshing lemon iced tea, lightly sweetened.", "image": "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80"},
        {"name": "Aloe Vera Drink", "price": 2.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 160, "description": "Aloe vera juice with real pulp chunks.", "image": "https://images.unsplash.com/photo-1596392927852-2a18bf04f233?w=400&q=80"},
        {"name": "Hot Chocolate Mix", "price": 5.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 110, "description": "Rich and creamy hot chocolate powder mix.", "image": "https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?w=400&q=80"},
    ],
    "snacks-chips": [
        {"name": "Classic Potato Chips", "price": 3.49, "compare_at_price": 4.49, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 250, "description": "Crispy, lightly salted classic potato chips.", "image": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&q=80"},
        {"name": "Mixed Nuts", "price": 7.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 120, "description": "Premium roasted mixed nuts — almonds, cashews, pistachios.", "image": "https://images.unsplash.com/photo-1599599810694-b5b37304c041?w=400&q=80"},
        {"name": "Granola Bars (6)", "price": 4.99, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 180, "description": "Crunchy oat and honey granola bars.", "image": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80"},
        {"name": "Tortilla Chips", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 200, "description": "Salted corn tortilla chips, great with salsa.", "image": "https://images.unsplash.com/photo-1600952841320-db92ec4047ca?w=400&q=80"},
        {"name": "Popcorn", "price": 2.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 220, "description": "Butter-flavored microwave popcorn.", "image": "https://images.unsplash.com/photo-1585652757141-8837d023c12a?w=400&q=80"},
        {"name": "Trail Mix", "price": 6.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Energizing trail mix with nuts, seeds and dried fruits.", "image": "https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=400&q=80"},
        {"name": "Rice Crackers", "price": 3.29, "unit_type": "pack", "unit_value": 1, "stock_quantity": 150, "description": "Light and crunchy Asian rice crackers.", "image": "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=400&q=80"},
        {"name": "Pretzels", "price": 2.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 170, "description": "Classic salted pretzels, baked not fried.", "image": "https://images.unsplash.com/photo-1590005176489-db2e714711fc?w=400&q=80"},
        {"name": "Dried Mango", "price": 4.49, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 130, "description": "Naturally sweet dried mango slices.", "image": "https://images.unsplash.com/photo-1596591606975-97ee5cef3a1e?w=400&q=80"},
        {"name": "Veggie Sticks", "price": 3.79, "unit_type": "pack", "unit_value": 1, "stock_quantity": 110, "description": "Baked vegetable sticks, a healthier snack option.", "image": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80"},
    ],
    "frozen-foods": [
        {"name": "Frozen Pizza", "price": 6.99, "compare_at_price": 8.99, "unit_type": "piece", "unit_value": 1, "is_featured": True, "stock_quantity": 100, "description": "Stone-baked margherita pizza, ready in 15 minutes.", "image": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80"},
        {"name": "Ice Cream Vanilla", "price": 5.99, "unit_type": "litre", "unit_value": 1, "stock_quantity": 80, "description": "Premium vanilla bean ice cream.", "image": "https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=400&q=80"},
        {"name": "Frozen Berries Mix", "price": 4.99, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 120, "description": "Mixed frozen berries for smoothies and desserts.", "image": "https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=400&q=80"},
        {"name": "Frozen French Fries", "price": 3.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 200, "description": "Crispy golden french fries, oven-ready.", "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&q=80"},
        {"name": "Fish Fingers", "price": 5.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 90, "description": "Breaded fish fingers, crispy and golden.", "image": "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&q=80"},
        {"name": "Frozen Dumplings", "price": 7.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 70, "description": "Handmade pork and vegetable dumplings.", "image": "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400&q=80"},
        {"name": "Frozen Vegetables Mix", "price": 2.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 180, "description": "Mixed vegetables — peas, carrots, corn and beans.", "image": "https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=400&q=80"},
        {"name": "Waffles (8 pack)", "price": 4.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Belgian-style waffles, just pop in the toaster.", "image": "https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=400&q=80"},
        {"name": "Frozen Chicken Nuggets", "price": 6.49, "compare_at_price": 7.99, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 130, "description": "Crispy chicken nuggets, kids' favorite!", "image": "https://images.unsplash.com/photo-1562967916-eb82221dfb44?w=400&q=80"},
        {"name": "Frozen Edamame", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 85, "description": "Shelled frozen edamame beans, high in protein.", "image": "https://images.unsplash.com/photo-1564894809611-1742fc40ed80?w=400&q=80"},
    ],
    "rice-grains": [
        {"name": "Basmati Rice", "price": 8.99, "compare_at_price": 10.99, "unit_type": "kg", "unit_value": 5, "is_featured": True, "stock_quantity": 150, "description": "Premium long-grain basmati rice, aromatic and fluffy.", "image": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&q=80"},
        {"name": "Quinoa", "price": 6.99, "unit_type": "kg", "unit_value": 1, "is_organic": True, "stock_quantity": 100, "description": "Organic white quinoa, complete protein grain.", "image": "https://images.unsplash.com/photo-1586943101559-4cdcf86a6f5f?w=400&q=80"},
        {"name": "Rolled Oats", "price": 3.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 200, "description": "Whole grain rolled oats for a healthy breakfast.", "image": "https://images.unsplash.com/photo-1614961233913-a5113e3b3093?w=400&q=80"},
        {"name": "Brown Rice", "price": 5.49, "unit_type": "kg", "unit_value": 2, "stock_quantity": 130, "description": "Nutritious brown rice, high in fiber.", "image": "https://images.unsplash.com/photo-1536304993881-460e32f50f73?w=400&q=80"},
        {"name": "Jasmine Rice", "price": 7.49, "unit_type": "kg", "unit_value": 5, "stock_quantity": 110, "description": "Fragrant Thai jasmine rice, perfect with curries.", "image": "https://images.unsplash.com/photo-1594756202469-9ff9799b2e4e?w=400&q=80"},
        {"name": "Cornflakes", "price": 3.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 180, "description": "Crispy golden cornflakes breakfast cereal.", "image": "https://images.unsplash.com/photo-1521483451569-e33803c0330c?w=400&q=80"},
        {"name": "Muesli Mix", "price": 5.99, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 90, "description": "Swiss-style muesli with nuts, seeds and dried fruits.", "image": "https://images.unsplash.com/photo-1517093602195-b40af9688d55?w=400&q=80"},
        {"name": "Red Lentils", "price": 2.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 250, "description": "Split red lentils, quick-cooking and nutritious.", "image": "https://images.unsplash.com/photo-1585015701361-5fa0a1889a52?w=400&q=80"},
        {"name": "Chickpeas", "price": 2.49, "unit_type": "kg", "unit_value": 1, "stock_quantity": 220, "description": "Dried chickpeas for hummus, curries and salads.", "image": "https://images.unsplash.com/photo-1515543904279-3f88b0e4d51e?w=400&q=80"},
        {"name": "Couscous", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Instant Moroccan couscous, ready in 5 minutes.", "image": "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400&q=80"},
    ],
    "spices-herbs": [
        {"name": "Ground Turmeric", "price": 3.99, "unit_type": "gram", "unit_value": 200, "is_organic": True, "stock_quantity": 150, "description": "Golden organic turmeric powder, anti-inflammatory.", "image": "https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=400&q=80"},
        {"name": "Black Pepper", "price": 4.49, "unit_type": "gram", "unit_value": 200, "stock_quantity": 180, "description": "Freshly ground Malabar black pepper.", "image": "https://images.unsplash.com/photo-1599909533700-2ffce4b7d13d?w=400&q=80"},
        {"name": "Cumin Seeds", "price": 3.49, "unit_type": "gram", "unit_value": 200, "stock_quantity": 160, "description": "Aromatic whole cumin seeds for tempering.", "image": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=80"},
        {"name": "Red Chilli Powder", "price": 2.99, "unit_type": "gram", "unit_value": 200, "stock_quantity": 200, "description": "Hot and vibrant red chilli powder.", "image": "https://images.unsplash.com/photo-1583119022894-919a68a3d0e3?w=400&q=80"},
        {"name": "Cinnamon Sticks", "price": 5.99, "unit_type": "gram", "unit_value": 100, "stock_quantity": 120, "description": "Ceylon cinnamon sticks, sweet and aromatic.", "image": "https://images.unsplash.com/photo-1587132137056-bfbf0166836e?w=400&q=80"},
        {"name": "Fresh Basil", "price": 1.99, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 90, "description": "Fresh sweet basil leaves, Italian classic.", "image": "https://images.unsplash.com/photo-1618164435735-413d3b066c9a?w=400&q=80"},
        {"name": "Bay Leaves", "price": 2.49, "unit_type": "gram", "unit_value": 50, "stock_quantity": 140, "description": "Dried bay leaves for soups and stews.", "image": "https://images.unsplash.com/photo-1591105575616-daeca5e92e39?w=400&q=80"},
        {"name": "Garam Masala", "price": 4.99, "unit_type": "gram", "unit_value": 200, "is_featured": True, "stock_quantity": 110, "description": "Authentic Indian garam masala spice blend.", "image": "https://images.unsplash.com/photo-1532336414036-cf082815da68?w=400&q=80"},
        {"name": "Oregano Dried", "price": 2.79, "unit_type": "gram", "unit_value": 100, "stock_quantity": 130, "description": "Mediterranean dried oregano for pizza and pasta.", "image": "https://images.unsplash.com/photo-1506807803488-8eafc15316c7?w=400&q=80"},
        {"name": "Saffron", "price": 12.99, "unit_type": "gram", "unit_value": 5, "is_featured": True, "stock_quantity": 50, "description": "Premium Kashmir saffron threads, the most precious spice.", "image": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80"},
    ],
    "cooking-oil-ghee": [
        {"name": "Extra Virgin Olive Oil", "price": 9.99, "compare_at_price": 12.99, "unit_type": "litre", "unit_value": 1, "is_featured": True, "is_organic": True, "stock_quantity": 120, "description": "Cold-pressed Italian extra virgin olive oil.", "image": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&q=80"},
        {"name": "Coconut Oil", "price": 7.99, "unit_type": "litre", "unit_value": 1, "is_organic": True, "stock_quantity": 100, "description": "Virgin coconut oil for cooking and skincare.", "image": "https://images.unsplash.com/photo-1526947425960-945c6e72858f?w=400&q=80"},
        {"name": "Sunflower Oil", "price": 4.99, "unit_type": "litre", "unit_value": 2, "stock_quantity": 200, "description": "Light refined sunflower oil for everyday cooking.", "image": "https://images.unsplash.com/photo-1612104293859-a22a7d31e2c4?w=400&q=80"},
        {"name": "Pure Ghee", "price": 11.99, "unit_type": "kg", "unit_value": 1, "is_featured": True, "stock_quantity": 80, "description": "Traditional clarified butter (ghee), rich and aromatic.", "image": "https://images.unsplash.com/photo-1631452180539-96aca7d48617?w=400&q=80"},
        {"name": "Avocado Oil", "price": 8.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 70, "description": "High smoke point avocado oil for grilling.", "image": "https://images.unsplash.com/photo-1620706857370-e1b9770e8bb1?w=400&q=80"},
        {"name": "Sesame Oil", "price": 5.49, "unit_type": "ml", "unit_value": 500, "stock_quantity": 90, "description": "Toasted sesame oil for Asian cuisine.", "image": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=80"},
        {"name": "Mustard Oil", "price": 4.49, "unit_type": "litre", "unit_value": 1, "stock_quantity": 110, "description": "Cold-pressed mustard oil with pungent flavor.", "image": "https://images.unsplash.com/photo-1599321329438-84ee65db5e55?w=400&q=80"},
        {"name": "Peanut Oil", "price": 5.99, "unit_type": "litre", "unit_value": 1, "stock_quantity": 130, "description": "Roasted peanut oil, perfect for frying.", "image": "https://images.unsplash.com/photo-1599321329438-84ee65db5e55?w=400&q=80"},
        {"name": "Vegetable Oil", "price": 3.99, "unit_type": "litre", "unit_value": 2, "stock_quantity": 250, "description": "All-purpose vegetable cooking oil.", "image": "https://images.unsplash.com/photo-1612104293859-a22a7d31e2c4?w=400&q=80"},
        {"name": "Truffle Oil", "price": 14.99, "unit_type": "ml", "unit_value": 250, "stock_quantity": 30, "description": "Black truffle infused olive oil for gourmet dishes.", "image": "https://images.unsplash.com/photo-1597058712635-3182d1eab066?w=400&q=80"},
    ],
    "pasta-noodles": [
        {"name": "Spaghetti", "price": 2.49, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 250, "description": "Classic Italian spaghetti, durum wheat semolina.", "image": "https://images.unsplash.com/photo-1551462147-ff685ef09e4a?w=400&q=80"},
        {"name": "Penne Pasta", "price": 2.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 220, "description": "Penne rigate pasta, holds sauce perfectly.", "image": "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400&q=80"},
        {"name": "Ramen Noodles (5 pack)", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 180, "description": "Japanese-style instant ramen noodles.", "image": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&q=80"},
        {"name": "Egg Noodles", "price": 3.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 140, "description": "Traditional Chinese egg noodles for stir-fry.", "image": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=400&q=80"},
        {"name": "Lasagna Sheets", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Ready-to-use lasagna sheets, no pre-cooking needed.", "image": "https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=400&q=80"},
        {"name": "Rice Noodles", "price": 2.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 160, "description": "Thin rice vermicelli noodles for pad thai.", "image": "https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400&q=80"},
        {"name": "Fusilli", "price": 2.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 190, "description": "Spiral fusilli pasta, great for pasta salads.", "image": "https://images.unsplash.com/photo-1551462147-37885acc36f1?w=400&q=80"},
        {"name": "Udon Noodles", "price": 4.29, "unit_type": "pack", "unit_value": 1, "stock_quantity": 80, "description": "Thick Japanese udon noodles, chewy texture.", "image": "https://images.unsplash.com/photo-1618164435735-413d3b066c9a?w=400&q=80"},
        {"name": "Whole Wheat Pasta", "price": 3.49, "unit_type": "pack", "unit_value": 1, "is_organic": True, "stock_quantity": 120, "description": "Organic whole wheat penne, higher in fiber.", "image": "https://images.unsplash.com/photo-1551462147-ff685ef09e4a?w=400&q=80"},
        {"name": "Mac & Cheese Box", "price": 1.99, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 300, "description": "Classic mac and cheese dinner, ready in 10 minutes.", "image": "https://images.unsplash.com/photo-1543339494-b4cd4f7ba686?w=400&q=80"},
    ],
    "sauces-condiments": [
        {"name": "Tomato Ketchup", "price": 2.99, "unit_type": "ml", "unit_value": 500, "is_featured": True, "stock_quantity": 300, "description": "Classic tomato ketchup, tangy and sweet.", "image": "https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=400&q=80"},
        {"name": "Soy Sauce", "price": 3.49, "unit_type": "ml", "unit_value": 500, "stock_quantity": 180, "description": "Naturally brewed soy sauce for Asian cooking.", "image": "https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400&q=80"},
        {"name": "Mayonnaise", "price": 3.99, "unit_type": "ml", "unit_value": 400, "stock_quantity": 200, "description": "Creamy egg mayonnaise, classic recipe.", "image": "https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?w=400&q=80"},
        {"name": "Hot Sauce", "price": 4.49, "unit_type": "ml", "unit_value": 350, "stock_quantity": 140, "description": "Fiery hot sauce made with habanero peppers.", "image": "https://images.unsplash.com/photo-1587131782738-de30ea91a542?w=400&q=80"},
        {"name": "Pesto Sauce", "price": 5.99, "unit_type": "ml", "unit_value": 300, "stock_quantity": 80, "description": "Traditional basil pesto with pine nuts and parmesan.", "image": "https://images.unsplash.com/photo-1592417817098-8fd3d9eb14a5?w=400&q=80"},
        {"name": "BBQ Sauce", "price": 3.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 160, "description": "Smoky barbecue sauce for grilling and dipping.", "image": "https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400&q=80"},
        {"name": "Italian Dressing", "price": 3.49, "unit_type": "ml", "unit_value": 350, "stock_quantity": 110, "description": "Zesty Italian vinaigrette salad dressing.", "image": "https://images.unsplash.com/photo-1621959810242-a6cd905f81c1?w=400&q=80"},
        {"name": "Honey", "price": 7.99, "unit_type": "ml", "unit_value": 500, "is_organic": True, "stock_quantity": 90, "description": "Raw organic wildflower honey, unfiltered.", "image": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80"},
        {"name": "Mustard Sauce", "price": 2.99, "unit_type": "ml", "unit_value": 300, "stock_quantity": 130, "description": "Dijon mustard with a smooth, tangy kick.", "image": "https://images.unsplash.com/photo-1528750717929-32abb73d3bd9?w=400&q=80"},
        {"name": "Marinara Sauce", "price": 4.49, "unit_type": "ml", "unit_value": 500, "is_featured": True, "stock_quantity": 110, "description": "Homestyle marinara sauce with fresh tomatoes and herbs.", "image": "https://images.unsplash.com/photo-1534940519139-f860fb3c7e38?w=400&q=80"},
    ],
    "organic-health": [
        {"name": "Chia Seeds", "price": 6.99, "unit_type": "gram", "unit_value": 500, "is_organic": True, "is_featured": True, "stock_quantity": 120, "description": "Organic chia seeds, superfood rich in omega-3.", "image": "https://images.unsplash.com/photo-1514536338817-6f8d85e95b88?w=400&q=80"},
        {"name": "Flax Seeds", "price": 4.99, "unit_type": "gram", "unit_value": 500, "is_organic": True, "stock_quantity": 140, "description": "Golden flax seeds, high in fiber and lignans.", "image": "https://images.unsplash.com/photo-1604170597784-14c1a3e7e4b1?w=400&q=80"},
        {"name": "Almond Butter", "price": 9.99, "unit_type": "gram", "unit_value": 400, "is_organic": True, "stock_quantity": 70, "description": "Smooth organic almond butter, no added sugar.", "image": "https://images.unsplash.com/photo-1612187310369-4fa9b9c6e997?w=400&q=80"},
        {"name": "Whey Protein", "price": 29.99, "unit_type": "kg", "unit_value": 1, "stock_quantity": 60, "description": "Chocolate whey protein powder, 25g protein per serve.", "image": "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=400&q=80"},
        {"name": "Apple Cider Vinegar", "price": 5.49, "unit_type": "ml", "unit_value": 500, "is_organic": True, "is_featured": True, "stock_quantity": 100, "description": "Raw unfiltered apple cider vinegar with the mother.", "image": "https://images.unsplash.com/photo-1576673442511-7e39b6545c87?w=400&q=80"},
        {"name": "Spirulina Powder", "price": 14.99, "unit_type": "gram", "unit_value": 200, "is_organic": True, "stock_quantity": 50, "description": "Blue-green algae superfood powder.", "image": "https://images.unsplash.com/photo-1622396636133-ac99d2a7a99a?w=400&q=80"},
        {"name": "Peanut Butter", "price": 5.99, "unit_type": "gram", "unit_value": 500, "stock_quantity": 160, "description": "Crunchy natural peanut butter, no palm oil.", "image": "https://images.unsplash.com/photo-1612187310369-4fa9b9c6e997?w=400&q=80"},
        {"name": "Coconut Sugar", "price": 4.49, "unit_type": "gram", "unit_value": 500, "is_organic": True, "stock_quantity": 80, "description": "Organic coconut palm sugar, low GI sweetener.", "image": "https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?w=400&q=80"},
        {"name": "Hemp Seeds", "price": 8.99, "unit_type": "gram", "unit_value": 300, "is_organic": True, "stock_quantity": 60, "description": "Hulled hemp seeds, complete plant protein.", "image": "https://images.unsplash.com/photo-1515543904279-3f88b0e4d51e?w=400&q=80"},
        {"name": "Matcha Powder", "price": 11.99, "unit_type": "gram", "unit_value": 100, "is_organic": True, "stock_quantity": 70, "description": "Ceremonial grade Japanese matcha green tea powder.", "image": "https://images.unsplash.com/photo-1515823064-d6e0c04616a7?w=400&q=80"},
    ],
    "baby-care": [
        {"name": "Baby Formula", "price": 24.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Stage 1 infant formula, gentle nutrition.", "image": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80"},
        {"name": "Baby Cereal", "price": 4.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 120, "description": "Rice cereal for babies 6 months+.", "image": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80"},
        {"name": "Baby Wipes (80)", "price": 3.49, "compare_at_price": 4.99, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 200, "description": "Gentle fragrance-free baby wipes.", "image": "https://images.unsplash.com/photo-1584839404042-8bc42ff3696a?w=400&q=80"},
        {"name": "Diapers (Size M)", "price": 12.99, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 150, "description": "Ultra-absorbent diapers for overnight comfort.", "image": "https://images.unsplash.com/photo-1584839404042-8bc42ff3696a?w=400&q=80"},
        {"name": "Baby Shampoo", "price": 5.99, "unit_type": "ml", "unit_value": 300, "stock_quantity": 90, "description": "Tear-free gentle baby shampoo.", "image": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80"},
        {"name": "Baby Food Puree", "price": 2.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 180, "description": "Organic apple and banana baby food pouch.", "image": "https://images.unsplash.com/photo-1569740862291-4a08e32f3974?w=400&q=80"},
        {"name": "Baby Lotion", "price": 6.49, "unit_type": "ml", "unit_value": 300, "stock_quantity": 80, "description": "Moisturizing baby body lotion, hypoallergenic.", "image": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80"},
        {"name": "Teething Biscuits", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "Organic teething biscuits for sore gums.", "image": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80"},
        {"name": "Baby Sippy Cup", "price": 7.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 60, "description": "Spill-proof training sippy cup, BPA-free.", "image": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80"},
        {"name": "Baby Rash Cream", "price": 5.49, "unit_type": "gram", "unit_value": 100, "stock_quantity": 110, "description": "Zinc oxide diaper rash cream, fast relief.", "image": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80"},
    ],
    "personal-care": [
        {"name": "Shampoo", "price": 6.99, "unit_type": "ml", "unit_value": 400, "stock_quantity": 150, "description": "Keratin-infused shampoo for silky smooth hair.", "image": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80"},
        {"name": "Body Wash", "price": 5.99, "compare_at_price": 7.99, "unit_type": "ml", "unit_value": 500, "is_featured": True, "stock_quantity": 180, "description": "Moisturizing body wash with vitamin E.", "image": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80"},
        {"name": "Toothpaste", "price": 3.49, "unit_type": "gram", "unit_value": 150, "stock_quantity": 300, "description": "Whitening toothpaste with fluoride protection.", "image": "https://images.unsplash.com/photo-1559439127-b0e27a04da07?w=400&q=80"},
        {"name": "Deodorant", "price": 4.99, "unit_type": "ml", "unit_value": 150, "stock_quantity": 160, "description": "48-hour fresh deodorant roll-on.", "image": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80"},
        {"name": "Face Wash", "price": 7.49, "unit_type": "ml", "unit_value": 150, "stock_quantity": 120, "description": "Gentle foaming face wash for all skin types.", "image": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80"},
        {"name": "Hand Sanitizer", "price": 2.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 250, "description": "70% alcohol hand sanitizer gel.", "image": "https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=400&q=80"},
        {"name": "Sunscreen SPF 50", "price": 9.99, "unit_type": "ml", "unit_value": 100, "stock_quantity": 80, "description": "Broad spectrum SPF 50 sunscreen, water-resistant.", "image": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80"},
        {"name": "Razors (4 pack)", "price": 8.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 100, "description": "5-blade razors with moisturizing strip.", "image": "https://images.unsplash.com/photo-1593787406338-e72e92ac9dc2?w=400&q=80"},
        {"name": "Cotton Pads (100)", "price": 2.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 200, "description": "Soft cotton pads for makeup removal.", "image": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80"},
        {"name": "Lip Balm", "price": 1.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 180, "description": "SPF 15 moisturizing lip balm, cherry flavor.", "image": "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&q=80"},
    ],
    "household-cleaning": [
        {"name": "Dish Soap", "price": 3.49, "unit_type": "ml", "unit_value": 750, "is_featured": True, "stock_quantity": 250, "description": "Lemon-scented dish washing liquid.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Laundry Detergent", "price": 8.99, "unit_type": "litre", "unit_value": 2, "stock_quantity": 150, "description": "Concentrated laundry detergent, fresh scent.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Paper Towels (6)", "price": 5.99, "compare_at_price": 7.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 180, "description": "Super absorbent paper towel rolls.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Trash Bags (30)", "price": 4.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 200, "description": "Heavy-duty trash bags with drawstring.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "All-Purpose Cleaner", "price": 3.99, "unit_type": "ml", "unit_value": 750, "stock_quantity": 160, "description": "Antibacterial multi-surface spray cleaner.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Toilet Cleaner", "price": 2.99, "unit_type": "ml", "unit_value": 500, "stock_quantity": 180, "description": "Powerful toilet bowl cleaner with bleach.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Sponges (5 pack)", "price": 2.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 220, "description": "Non-scratch scrub sponges for kitchen.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Glass Cleaner", "price": 3.49, "unit_type": "ml", "unit_value": 500, "stock_quantity": 140, "description": "Streak-free glass and window cleaner.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Aluminum Foil", "price": 3.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 190, "description": "Heavy-duty aluminum foil roll, 25 meters.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
        {"name": "Cling Wrap", "price": 2.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 200, "description": "BPA-free food cling wrap, easy tear.", "image": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80"},
    ],
    "chocolates-sweets": [
        {"name": "Dark Chocolate Bar", "price": 3.99, "compare_at_price": 5.49, "unit_type": "gram", "unit_value": 200, "is_featured": True, "stock_quantity": 150, "description": "72% cocoa dark chocolate, rich and smooth.", "image": "https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=400&q=80"},
        {"name": "Milk Chocolate", "price": 2.99, "unit_type": "gram", "unit_value": 150, "stock_quantity": 200, "description": "Creamy Swiss milk chocolate bar.", "image": "https://images.unsplash.com/photo-1511381939415-e44015466834?w=400&q=80"},
        {"name": "Chocolate Truffles", "price": 8.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 70, "description": "Assorted Belgian chocolate truffles.", "image": "https://images.unsplash.com/photo-1548907040-4baa42d10919?w=400&q=80"},
        {"name": "Gummy Bears", "price": 2.49, "unit_type": "gram", "unit_value": 250, "stock_quantity": 180, "description": "Fruity gummy bears, assorted flavors.", "image": "https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=400&q=80"},
        {"name": "Caramel Candies", "price": 3.49, "unit_type": "gram", "unit_value": 300, "stock_quantity": 120, "description": "Soft salted caramel candies, handmade.", "image": "https://images.unsplash.com/photo-1600359756098-8bc52195bbf4?w=400&q=80"},
        {"name": "White Chocolate", "price": 3.49, "unit_type": "gram", "unit_value": 150, "stock_quantity": 140, "description": "Smooth creamy white chocolate bar.", "image": "https://images.unsplash.com/photo-1587132137056-bfbf0166836e?w=400&q=80"},
        {"name": "Chocolate Cookies", "price": 4.49, "unit_type": "pack", "unit_value": 1, "is_featured": True, "stock_quantity": 160, "description": "Double chocolate chip cookies, freshly baked.", "image": "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400&q=80"},
        {"name": "Hazelnut Spread", "price": 5.99, "unit_type": "gram", "unit_value": 400, "stock_quantity": 100, "description": "Chocolate hazelnut spread for toast and crepes.", "image": "https://images.unsplash.com/photo-1530016142778-8b8c5ba6f40e?w=400&q=80"},
        {"name": "Lollipops (10)", "price": 1.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 250, "description": "Colorful fruit-flavored lollipops.", "image": "https://images.unsplash.com/photo-1575224300306-1b8da36e726b?w=400&q=80"},
        {"name": "Marshmallows", "price": 2.99, "unit_type": "gram", "unit_value": 300, "stock_quantity": 130, "description": "Fluffy vanilla marshmallows for S'mores.", "image": "https://images.unsplash.com/photo-1553452118-621e1f860f43?w=400&q=80"},
    ],
    "pet-supplies": [
        {"name": "Dog Food (Dry)", "price": 19.99, "compare_at_price": 24.99, "unit_type": "kg", "unit_value": 5, "is_featured": True, "stock_quantity": 80, "description": "Premium dry dog food, chicken and rice recipe.", "image": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80"},
        {"name": "Cat Food (Wet)", "price": 1.49, "unit_type": "pack", "unit_value": 1, "stock_quantity": 200, "description": "Gourmet wet cat food, salmon pâté.", "image": "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400&q=80"},
        {"name": "Dog Treats", "price": 6.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 120, "description": "Natural beef jerky treats for dogs.", "image": "https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=400&q=80"},
        {"name": "Cat Litter", "price": 9.99, "unit_type": "kg", "unit_value": 10, "stock_quantity": 100, "description": "Clumping clay cat litter, low dust formula.", "image": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80"},
        {"name": "Pet Shampoo", "price": 7.49, "unit_type": "ml", "unit_value": 500, "stock_quantity": 90, "description": "Gentle oatmeal pet shampoo, soothes skin.", "image": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80"},
        {"name": "Dog Chew Toy", "price": 5.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 70, "description": "Durable rubber chew toy for aggressive chewers.", "image": "https://images.unsplash.com/photo-1535930749574-1399327ce78f?w=400&q=80"},
        {"name": "Cat Catnip Toy", "price": 3.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 100, "description": "Interactive catnip mouse toy for cats.", "image": "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400&q=80"},
        {"name": "Fish Food", "price": 4.49, "unit_type": "gram", "unit_value": 200, "stock_quantity": 80, "description": "Tropical fish food flakes, color-enhancing.", "image": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80"},
        {"name": "Pet Poop Bags (60)", "price": 2.99, "unit_type": "pack", "unit_value": 1, "stock_quantity": 180, "description": "Biodegradable pet waste bags, lavender scented.", "image": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80"},
        {"name": "Dog Leash", "price": 11.99, "unit_type": "piece", "unit_value": 1, "stock_quantity": 50, "description": "Retractable dog leash, 5 meter length.", "image": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80"},
    ],
}


async def seed():
    """Seed the database with categories, products, and images."""
    async with AsyncSessionLocal() as session:
        # Check if data already exists
        result = await session.execute(
            text("SELECT COUNT(*) FROM product_categories")
        )
        count = result.scalar()
        if count and count > 0:
            print(f"Database already has {count} categories. Skipping seed.")
            return

        print("Seeding database...")

        # 1. Create a vendor user + vendor
        vendor_user_id = uuid.uuid4()
        vendor_user = User(
            id=vendor_user_id,
            email="vendor@grocery.com",
            phone="+1234567890",
            hashed_password=hash_password("vendor123"),
            full_name="GroceryMart Vendor",
            role=UserRole.VENDOR,
            is_active=True,
            is_verified=True,
        )
        session.add(vendor_user)
        await session.flush()

        vendor_id = uuid.uuid4()
        vendor = Vendor(
            id=vendor_id,
            user_id=vendor_user_id,
            store_name="FreshMart Grocery",
            store_description="Your one-stop shop for fresh groceries and daily essentials",
            address="123 Market Street",
            city="New York",
            state="NY",
            postal_code="10001",
            latitude=40.7128,
            longitude=-74.0060,
            delivery_radius_km=15.0,
            commission_rate=10.0,
            status=VendorStatus.APPROVED,
            is_active=True,
            rating=4.5,
        )
        session.add(vendor)
        await session.flush()

        # 2. Create categories
        category_map = {}  # slug -> id
        for cat_data in CATEGORIES:
            cat_id = uuid.uuid4()
            category = ProductCategory(
                id=cat_id,
                name=cat_data["name"],
                slug=cat_data["slug"],
                description=cat_data["description"],
                icon_url=f"assets/images/category_icons/{cat_data['slug']}.png",
                image_url=f"assets/images/categories/{cat_data['slug']}.jpg",
                sort_order=cat_data["sort_order"],
                is_active=True,
            )
            session.add(category)
            category_map[cat_data["slug"]] = cat_id
        await session.flush()
        print(f"  Created {len(CATEGORIES)} categories")

        # 3. Create products with images
        total_products = 0
        for cat_slug, products in PRODUCTS_BY_CATEGORY.items():
            cat_id = category_map[cat_slug]
            for i, p in enumerate(products):
                product_id = uuid.uuid4()
                slug = p["name"].lower().replace(" ", "-").replace("(", "").replace(")", "").replace("&", "and")

                unit_type_map = {
                    "kg": UnitType.KG,
                    "gram": UnitType.GRAM,
                    "litre": UnitType.LITRE,
                    "ml": UnitType.ML,
                    "piece": UnitType.PIECE,
                    "dozen": UnitType.DOZEN,
                    "pack": UnitType.PACK,
                }

                product = Product(
                    id=product_id,
                    vendor_id=vendor_id,
                    category_id=cat_id,
                    name=p["name"],
                    slug=f"{slug}-{str(product_id)[:8]}",
                    description=p.get("description", ""),
                    short_description=p.get("description", "")[:200] if p.get("description") else None,
                    price=p["price"],
                    compare_at_price=p.get("compare_at_price"),
                    cost_price=round(p["price"] * 0.6, 2),
                    sku=f"SKU-{cat_slug[:3].upper()}-{i+1:03d}",
                    stock_quantity=p.get("stock_quantity", 100),
                    unit_type=unit_type_map.get(p.get("unit_type", "kg"), UnitType.KG),
                    unit_value=p.get("unit_value", 1.0),
                    status=ProductStatus.ACTIVE,
                    is_featured=p.get("is_featured", False),
                    is_organic=p.get("is_organic", False),
                    avg_rating=round(3.5 + (hash(p["name"]) % 15) / 10.0, 1),
                    total_reviews=(hash(p["name"]) % 200) + 5,
                    total_sold=(hash(p["name"]) % 500) + 10,
                    tags={"category": cat_slug},
                    nutritional_info={"calories": str(50 + (i * 20)), "serving_size": "100g"} if cat_slug in ["fresh-fruits", "fresh-vegetables", "dairy-eggs"] else None,
                )
                session.add(product)

                # Add product image (use local asset path)
                img_slug = _product_slug(p["name"])
                image = ProductImage(
                    id=uuid.uuid4(),
                    product_id=product_id,
                    image_url=f"assets/images/products/{img_slug}.jpg",
                    alt_text=p["name"],
                    sort_order=0,
                    is_primary=True,
                )
                session.add(image)
                total_products += 1

            await session.flush()

        await session.commit()
        print(f"  Created {total_products} products with images")
        print("Seeding complete!")


if __name__ == "__main__":
    asyncio.run(seed())
