# ==============================================================================
# routes/__init__.py - Routes Package Initializer
# ==============================================================================
# This file makes the 'routes' folder a Python package.
# When Python sees an __init__.py file in a folder, it treats that folder
# as a package that can be imported.
#
# Each route file in this folder defines a "Blueprint" - a group of related
# API endpoints. For example:
# - auth.py -> /api/auth/login, /api/auth/register
# - transactions.py -> /api/transactions/add, /api/transactions/list
# - budgets.py -> /api/budgets/create, /api/budgets/list
#
# These blueprints are registered in app/__init__.py (the create_app function).
# ==============================================================================
