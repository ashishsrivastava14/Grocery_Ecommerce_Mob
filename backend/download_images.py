"""Download all product and category images locally to the Flutter assets folder."""
import os
import re
import time
import urllib.request
import ssl

# Disable SSL verification for image downloads
ssl._create_default_https_context = ssl._create_unverified_context

FRONTEND_ASSETS = os.path.join(os.path.dirname(__file__), "..", "frontend", "assets", "images")
CATEGORIES_DIR = os.path.join(FRONTEND_ASSETS, "categories")
PRODUCTS_DIR = os.path.join(FRONTEND_ASSETS, "products")
ICONS_DIR = os.path.join(FRONTEND_ASSETS, "category_icons")

os.makedirs(CATEGORIES_DIR, exist_ok=True)
os.makedirs(PRODUCTS_DIR, exist_ok=True)
os.makedirs(ICONS_DIR, exist_ok=True)

# ─── Category icon URLs (flaticon PNGs) ───
CATEGORY_ICONS = {
    "fresh-fruits": "https://cdn-icons-png.flaticon.com/128/415/415682.png",
    "fresh-vegetables": "https://cdn-icons-png.flaticon.com/128/2153/2153786.png",
    "dairy-eggs": "https://cdn-icons-png.flaticon.com/128/3050/3050158.png",
    "bakery-bread": "https://cdn-icons-png.flaticon.com/128/3081/3081967.png",
    "meat-poultry": "https://cdn-icons-png.flaticon.com/128/1046/1046751.png",
    "seafood-fish": "https://cdn-icons-png.flaticon.com/128/2838/2838016.png",
    "beverages": "https://cdn-icons-png.flaticon.com/128/2405/2405479.png",
    "snacks-chips": "https://cdn-icons-png.flaticon.com/128/2553/2553691.png",
    "frozen-foods": "https://cdn-icons-png.flaticon.com/128/2965/2965567.png",
    "rice-grains": "https://cdn-icons-png.flaticon.com/128/3174/3174880.png",
    "spices-herbs": "https://cdn-icons-png.flaticon.com/128/2674/2674505.png",
    "cooking-oil-ghee": "https://cdn-icons-png.flaticon.com/128/5787/5787016.png",
    "pasta-noodles": "https://cdn-icons-png.flaticon.com/128/1471/1471262.png",
    "sauces-condiments": "https://cdn-icons-png.flaticon.com/128/2515/2515183.png",
    "organic-health": "https://cdn-icons-png.flaticon.com/128/2909/2909765.png",
    "baby-care": "https://cdn-icons-png.flaticon.com/128/3373/3373060.png",
    "personal-care": "https://cdn-icons-png.flaticon.com/128/2553/2553642.png",
    "household-cleaning": "https://cdn-icons-png.flaticon.com/128/995/995053.png",
    "chocolates-sweets": "https://cdn-icons-png.flaticon.com/128/3081/3081906.png",
    "pet-supplies": "https://cdn-icons-png.flaticon.com/128/2171/2171991.png",
}

# ─── Category banner image URLs ───
CATEGORY_IMAGES = {
    "fresh-fruits": "https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600&q=80",
    "fresh-vegetables": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80",
    "dairy-eggs": "https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=600&q=80",
    "bakery-bread": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80",
    "meat-poultry": "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=600&q=80",
    "seafood-fish": "https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=600&q=80",
    "beverages": "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=600&q=80",
    "snacks-chips": "https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=600&q=80",
    "frozen-foods": "https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=600&q=80",
    "rice-grains": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&q=80",
    "spices-herbs": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80",
    "cooking-oil-ghee": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&q=80",
    "pasta-noodles": "https://images.unsplash.com/photo-1551462147-37885acc36f1?w=600&q=80",
    "sauces-condiments": "https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=600&q=80",
    "organic-health": "https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=80",
    "baby-care": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=600&q=80",
    "personal-care": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=600&q=80",
    "household-cleaning": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=600&q=80",
    "chocolates-sweets": "https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=600&q=80",
    "pet-supplies": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600&q=80",
}

# ─── Product image URLs (slug -> url) ───
PRODUCT_IMAGES = {
    # Fresh Fruits
    "red-apple": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&q=80",
    "banana": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80",
    "fresh-strawberry": "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=400&q=80",
    "orange": "https://images.unsplash.com/photo-1547514701-42782101795e?w=400&q=80",
    "mango": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=400&q=80",
    "blueberry-pack": "https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=400&q=80",
    "green-grapes": "https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=400&q=80",
    "watermelon": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80",
    "pineapple": "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=400&q=80",
    "kiwi": "https://images.unsplash.com/photo-1618897996318-5a901fa6ca71?w=400&q=80",
    # Fresh Vegetables
    "broccoli": "https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=400&q=80",
    "tomatoes": "https://images.unsplash.com/photo-1546470427-0d4db154ceb8?w=400&q=80",
    "spinach-bundle": "https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&q=80",
    "bell-peppers": "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400&q=80",
    "carrots": "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&q=80",
    "cucumber": "https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&q=80",
    "onions": "https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400&q=80",
    "potatoes": "https://images.unsplash.com/photo-1508313880080-c4bef0730395?w=400&q=80",
    "avocado": "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400&q=80",
    "sweet-corn": "https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400&q=80",
    # Dairy & Eggs
    "whole-milk": "https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&q=80",
    "greek-yogurt": "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&q=80",
    "farm-eggs-12": "https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400&q=80",
    "cheddar-cheese": "https://images.unsplash.com/photo-1618164436241-4473940d1f5c?w=400&q=80",
    "butter-unsalted": "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400&q=80",
    "mozzarella": "https://images.unsplash.com/photo-1626957341926-98752fc2ba90?w=400&q=80",
    "heavy-cream": "https://images.unsplash.com/photo-1587657472852-16caaf1d0f22?w=400&q=80",
    "cottage-cheese": "https://images.unsplash.com/photo-1559561853-08451507cbe7?w=400&q=80",
    "almond-milk": "https://images.unsplash.com/photo-1600788886242-5c96aabe3757?w=400&q=80",
    "paneer": "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&q=80",
    # Bakery & Bread
    "sourdough-bread": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80",
    "whole-wheat-bread": "https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=400&q=80",
    "croissant-4-pack": "https://images.unsplash.com/photo-1555507036-ab1f4038024a?w=400&q=80",
    "bagels-6-pack": "https://images.unsplash.com/photo-1585535958672-2263af2b315c?w=400&q=80",
    "chocolate-muffin": "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400&q=80",
    "baguette": "https://images.unsplash.com/photo-1549931319-a545753d62ce?w=400&q=80",
    "cinnamon-roll": "https://images.unsplash.com/photo-1509365390695-33aee754301f?w=400&q=80",
    "focaccia": "https://images.unsplash.com/photo-1573140401552-3fab0b24306f?w=400&q=80",
    "danish-pastry": "https://images.unsplash.com/photo-1612240498936-65f5101365d2?w=400&q=80",
    "garlic-bread": "https://images.unsplash.com/photo-1619535860434-ba1d8fa12536?w=400&q=80",
    # Meat & Poultry
    "chicken-breast": "https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400&q=80",
    "ground-beef": "https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=400&q=80",
    "lamb-chops": "https://images.unsplash.com/photo-1603048297172-c92544798d5a?w=400&q=80",
    "whole-chicken": "https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=400&q=80",
    "turkey-breast": "https://images.unsplash.com/photo-1574672280600-4accfa5b6f98?w=400&q=80",
    "pork-tenderloin": "https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=400&q=80",
    "chicken-wings": "https://images.unsplash.com/photo-1527477396000-e27163b4bcd1?w=400&q=80",
    "beef-steak-ribeye": "https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400&q=80",
    "sausages-6-pack": "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&q=80",
    "duck-breast": "https://images.unsplash.com/photo-1606728035253-49e8a23146de?w=400&q=80",
    # Seafood & Fish
    "atlantic-salmon": "https://images.unsplash.com/photo-1499125562588-29fb8a56b5d5?w=400&q=80",
    "jumbo-shrimp": "https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400&q=80",
    "tuna-steak": "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&q=80",
    "cod-fillet": "https://images.unsplash.com/photo-1510130113581-82a1e1e50588?w=400&q=80",
    "crab-meat": "https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=400&q=80",
    "mussels": "https://images.unsplash.com/photo-1559742811-822babe4afb6?w=400&q=80",
    "tilapia-fillet": "https://images.unsplash.com/photo-1535140728325-a4d3707eee61?w=400&q=80",
    "lobster-tail": "https://images.unsplash.com/photo-1559564484-e48b3e040ff4?w=400&q=80",
    "sardines": "https://images.unsplash.com/photo-1599084993091-1cb5c0721cc6?w=400&q=80",
    "squid-rings": "https://images.unsplash.com/photo-1603073163308-9654c3fb70b5?w=400&q=80",
    # Beverages
    "orange-juice": "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80",
    "green-tea-20-bags": "https://images.unsplash.com/photo-1556881286-fc6915169721?w=400&q=80",
    "ground-coffee": "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&q=80",
    "coconut-water": "https://images.unsplash.com/photo-1585238342024-78d387f4132e?w=400&q=80",
    "sparkling-water": "https://images.unsplash.com/photo-1606168094336-48f205276929?w=400&q=80",
    "protein-smoothie": "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&q=80",
    "apple-cider": "https://images.unsplash.com/photo-1576673442511-7e39b6545c87?w=400&q=80",
    "iced-tea-lemon": "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80",
    "aloe-vera-drink": "https://images.unsplash.com/photo-1596392927852-2a18bf04f233?w=400&q=80",
    "hot-chocolate-mix": "https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?w=400&q=80",
    # Snacks & Chips
    "classic-potato-chips": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&q=80",
    "mixed-nuts": "https://images.unsplash.com/photo-1599599810694-b5b37304c041?w=400&q=80",
    "granola-bars-6": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80",
    "tortilla-chips": "https://images.unsplash.com/photo-1600952841320-db92ec4047ca?w=400&q=80",
    "popcorn": "https://images.unsplash.com/photo-1585652757141-8837d023c12a?w=400&q=80",
    "trail-mix": "https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=400&q=80",
    "rice-crackers": "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=400&q=80",
    "pretzels": "https://images.unsplash.com/photo-1590005176489-db2e714711fc?w=400&q=80",
    "dried-mango": "https://images.unsplash.com/photo-1596591606975-97ee5cef3a1e?w=400&q=80",
    "veggie-sticks": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80",
    # Frozen Foods
    "frozen-pizza": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80",
    "ice-cream-vanilla": "https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=400&q=80",
    "frozen-berries-mix": "https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=400&q=80",
    "frozen-french-fries": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&q=80",
    "fish-fingers": "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&q=80",
    "frozen-dumplings": "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400&q=80",
    "frozen-vegetables-mix": "https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=400&q=80",
    "waffles-8-pack": "https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=400&q=80",
    "frozen-chicken-nuggets": "https://images.unsplash.com/photo-1562967916-eb82221dfb44?w=400&q=80",
    "frozen-edamame": "https://images.unsplash.com/photo-1564894809611-1742fc40ed80?w=400&q=80",
    # Rice & Grains
    "basmati-rice": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&q=80",
    "quinoa": "https://images.unsplash.com/photo-1586943101559-4cdcf86a6f5f?w=400&q=80",
    "rolled-oats": "https://images.unsplash.com/photo-1614961233913-a5113e3b3093?w=400&q=80",
    "brown-rice": "https://images.unsplash.com/photo-1536304993881-460e32f50f73?w=400&q=80",
    "jasmine-rice": "https://images.unsplash.com/photo-1594756202469-9ff9799b2e4e?w=400&q=80",
    "cornflakes": "https://images.unsplash.com/photo-1521483451569-e33803c0330c?w=400&q=80",
    "muesli-mix": "https://images.unsplash.com/photo-1517093602195-b40af9688d55?w=400&q=80",
    "red-lentils": "https://images.unsplash.com/photo-1585015701361-5fa0a1889a52?w=400&q=80",
    "chickpeas": "https://images.unsplash.com/photo-1515543904279-3f88b0e4d51e?w=400&q=80",
    "couscous": "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400&q=80",
    # Spices & Herbs
    "ground-turmeric": "https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=400&q=80",
    "black-pepper": "https://images.unsplash.com/photo-1599909533700-2ffce4b7d13d?w=400&q=80",
    "cumin-seeds": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=80",
    "red-chilli-powder": "https://images.unsplash.com/photo-1583119022894-919a68a3d0e3?w=400&q=80",
    "cinnamon-sticks": "https://images.unsplash.com/photo-1587132137056-bfbf0166836e?w=400&q=80",
    "fresh-basil": "https://images.unsplash.com/photo-1618164435735-413d3b066c9a?w=400&q=80",
    "bay-leaves": "https://images.unsplash.com/photo-1591105575616-daeca5e92e39?w=400&q=80",
    "garam-masala": "https://images.unsplash.com/photo-1532336414036-cf082815da68?w=400&q=80",
    "oregano-dried": "https://images.unsplash.com/photo-1506807803488-8eafc15316c7?w=400&q=80",
    "saffron": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80",
    # Cooking Oil & Ghee
    "extra-virgin-olive-oil": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&q=80",
    "coconut-oil": "https://images.unsplash.com/photo-1526947425960-945c6e72858f?w=400&q=80",
    "sunflower-oil": "https://images.unsplash.com/photo-1612104293859-a22a7d31e2c4?w=400&q=80",
    "pure-ghee": "https://images.unsplash.com/photo-1631452180539-96aca7d48617?w=400&q=80",
    "avocado-oil": "https://images.unsplash.com/photo-1620706857370-e1b9770e8bb1?w=400&q=80",
    "sesame-oil": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=80",
    "mustard-oil": "https://images.unsplash.com/photo-1599321329438-84ee65db5e55?w=400&q=80",
    "peanut-oil": "https://images.unsplash.com/photo-1599321329438-84ee65db5e55?w=400&q=80",
    "vegetable-oil": "https://images.unsplash.com/photo-1612104293859-a22a7d31e2c4?w=400&q=80",
    "truffle-oil": "https://images.unsplash.com/photo-1597058712635-3182d1eab066?w=400&q=80",
    # Pasta & Noodles
    "spaghetti": "https://images.unsplash.com/photo-1551462147-ff685ef09e4a?w=400&q=80",
    "penne-pasta": "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400&q=80",
    "ramen-noodles-5-pack": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&q=80",
    "egg-noodles": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=400&q=80",
    "lasagna-sheets": "https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=400&q=80",
    "rice-noodles": "https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400&q=80",
    "fusilli": "https://images.unsplash.com/photo-1551462147-37885acc36f1?w=400&q=80",
    "udon-noodles": "https://images.unsplash.com/photo-1618164435735-413d3b066c9a?w=400&q=80",
    "whole-wheat-pasta": "https://images.unsplash.com/photo-1551462147-ff685ef09e4a?w=400&q=80",
    "mac-and-cheese-box": "https://images.unsplash.com/photo-1543339494-b4cd4f7ba686?w=400&q=80",
    # Sauces & Condiments
    "tomato-ketchup": "https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=400&q=80",
    "soy-sauce": "https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400&q=80",
    "mayonnaise": "https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?w=400&q=80",
    "hot-sauce": "https://images.unsplash.com/photo-1587131782738-de30ea91a542?w=400&q=80",
    "pesto-sauce": "https://images.unsplash.com/photo-1592417817098-8fd3d9eb14a5?w=400&q=80",
    "bbq-sauce": "https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400&q=80",
    "italian-dressing": "https://images.unsplash.com/photo-1621959810242-a6cd905f81c1?w=400&q=80",
    "honey": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&q=80",
    "mustard-sauce": "https://images.unsplash.com/photo-1528750717929-32abb73d3bd9?w=400&q=80",
    "marinara-sauce": "https://images.unsplash.com/photo-1534940519139-f860fb3c7e38?w=400&q=80",
    # Organic & Health
    "chia-seeds": "https://images.unsplash.com/photo-1514536338817-6f8d85e95b88?w=400&q=80",
    "flax-seeds": "https://images.unsplash.com/photo-1604170597784-14c1a3e7e4b1?w=400&q=80",
    "almond-butter": "https://images.unsplash.com/photo-1612187310369-4fa9b9c6e997?w=400&q=80",
    "whey-protein": "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=400&q=80",
    "apple-cider-vinegar": "https://images.unsplash.com/photo-1576673442511-7e39b6545c87?w=400&q=80",
    "spirulina-powder": "https://images.unsplash.com/photo-1622396636133-ac99d2a7a99a?w=400&q=80",
    "peanut-butter": "https://images.unsplash.com/photo-1612187310369-4fa9b9c6e997?w=400&q=80",
    "coconut-sugar": "https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?w=400&q=80",
    "hemp-seeds": "https://images.unsplash.com/photo-1515543904279-3f88b0e4d51e?w=400&q=80",
    "matcha-powder": "https://images.unsplash.com/photo-1515823064-d6e0c04616a7?w=400&q=80",
    # Baby Care
    "baby-formula": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80",
    "baby-cereal": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80",
    "baby-wipes-80": "https://images.unsplash.com/photo-1584839404042-8bc42ff3696a?w=400&q=80",
    "diapers-size-m": "https://images.unsplash.com/photo-1584839404042-8bc42ff3696a?w=400&q=80",
    "baby-shampoo": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80",
    "baby-food-puree": "https://images.unsplash.com/photo-1569740862291-4a08e32f3974?w=400&q=80",
    "baby-lotion": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80",
    "teething-biscuits": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80",
    "baby-sippy-cup": "https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80",
    "baby-rash-cream": "https://images.unsplash.com/photo-1590080374636-310c2979e163?w=400&q=80",
    # Personal Care
    "shampoo": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80",
    "body-wash": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80",
    "toothpaste": "https://images.unsplash.com/photo-1559439127-b0e27a04da07?w=400&q=80",
    "deodorant": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80",
    "face-wash": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80",
    "hand-sanitizer": "https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=400&q=80",
    "sunscreen-spf-50": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80",
    "razors-4-pack": "https://images.unsplash.com/photo-1593787406338-e72e92ac9dc2?w=400&q=80",
    "cotton-pads-100": "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80",
    "lip-balm": "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&q=80",
    # Household & Cleaning
    "dish-soap": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "laundry-detergent": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "paper-towels-6": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "trash-bags-30": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "all-purpose-cleaner": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "toilet-cleaner": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "sponges-5-pack": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "glass-cleaner": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "aluminum-foil": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    "cling-wrap": "https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&q=80",
    # Chocolates & Sweets
    "dark-chocolate-bar": "https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=400&q=80",
    "milk-chocolate": "https://images.unsplash.com/photo-1511381939415-e44015466834?w=400&q=80",
    "chocolate-truffles": "https://images.unsplash.com/photo-1548907040-4baa42d10919?w=400&q=80",
    "gummy-bears": "https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=400&q=80",
    "caramel-candies": "https://images.unsplash.com/photo-1600359756098-8bc42ff3696a?w=400&q=80",
    "white-chocolate": "https://images.unsplash.com/photo-1587132137056-bfbf0166836e?w=400&q=80",
    "chocolate-cookies": "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400&q=80",
    "hazelnut-spread": "https://images.unsplash.com/photo-1530016142778-8b8c5ba6f40e?w=400&q=80",
    "lollipops-10": "https://images.unsplash.com/photo-1575224300306-1b8da36e726b?w=400&q=80",
    "marshmallows": "https://images.unsplash.com/photo-1553452118-621e1f860f43?w=400&q=80",
    # Pet Supplies
    "dog-food-dry": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80",
    "cat-food-wet": "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400&q=80",
    "dog-treats": "https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=400&q=80",
    "cat-litter": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80",
    "pet-shampoo": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80",
    "dog-chew-toy": "https://images.unsplash.com/photo-1535930749574-1399327ce78f?w=400&q=80",
    "cat-catnip-toy": "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400&q=80",
    "fish-food": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80",
    "pet-poop-bags-60": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80",
    "dog-leash": "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&q=80",
}


def download_image(url, filepath):
    """Download image from URL to local file."""
    if os.path.exists(filepath):
        return True
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        with urllib.request.urlopen(req, timeout=30) as response:
            with open(filepath, "wb") as f:
                f.write(response.read())
        return True
    except Exception as e:
        print(f"  FAILED: {url} -> {e}")
        return False


def main():
    total = 0
    downloaded = 0
    failed = 0

    # Download category icons
    print("Downloading category icons...")
    for slug, url in CATEGORY_ICONS.items():
        total += 1
        filepath = os.path.join(ICONS_DIR, f"{slug}.png")
        if download_image(url, filepath):
            downloaded += 1
            print(f"  ✓ {slug}.png")
        else:
            failed += 1
        time.sleep(0.2)

    # Download category banner images
    print("\nDownloading category images...")
    for slug, url in CATEGORY_IMAGES.items():
        total += 1
        filepath = os.path.join(CATEGORIES_DIR, f"{slug}.jpg")
        if download_image(url, filepath):
            downloaded += 1
            print(f"  ✓ {slug}.jpg")
        else:
            failed += 1
        time.sleep(0.3)

    # Download product images
    print("\nDownloading product images...")
    for slug, url in PRODUCT_IMAGES.items():
        total += 1
        filepath = os.path.join(PRODUCTS_DIR, f"{slug}.jpg")
        if download_image(url, filepath):
            downloaded += 1
            print(f"  ✓ {slug}.jpg")
        else:
            failed += 1
        time.sleep(0.3)

    print(f"\n{'='*50}")
    print(f"Total: {total} | Downloaded: {downloaded} | Failed: {failed}")
    print(f"Images saved to: {FRONTEND_ASSETS}")


if __name__ == "__main__":
    main()
