import pandas as pd
import json
from pymongo import MongoClient


def denormalize_bgg_dataset():
    # Lecture du CSV avec séparateur ';'
    df = pd.read_csv("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/fichier brut/bgg_dataset.csv", sep=";")

    # Sélection des colonnes utiles
    df = df[[
        "Name", "Year Published", "Min Players", "Max Players",
        "Play Time", "Min Age", "Rating Average", "Complexity Average",
        "Mechanics", "Domains"
    ]]

    # Renommage des colonnes pour format JSON propre
    df = df.rename(columns={
        "Name": "Title",
        "Year Published": "Release Year",
        "Min Players": "Min Players",
        "Max Players": "Max Players",
        "Play Time": "Play Time (moyen)",
        "Min Age": "Min Age",
        "Rating Average": "Rating",
        "Complexity Average": "Difficulty",
        "Mechanics": "Mechanics",
        "Domains": "Genre"
    })

    # Conversion en dictionnaires
    records = df.to_dict(orient="records")

    # Export en JSON
    with open("bgg_dataset_clean.json", "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=4)

    print("✅ Conversion terminée avec succès ! Fichier 'bgg_dataset_clean.json' créé.")


#denormalize_bgg_dataset()



def denormalize_bgg_games_into_mongo_dataset():
    with open("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/bgg_dataset_clean.json", "r", encoding="utf-8") as f:
        bgg_games = json.load(f)

    df = pd.DataFrame.from_records(bgg_games)

    df = df.where(pd.notnull(df), None)

    bgg_games_records = df.to_dict(orient="records")

    myclient = MongoClient("mongodb://localhost:27017/")


    but3db = myclient["but3"]


    bgg_games_coll = but3db["bgg_games"]
    bgg_games_coll.delete_many({})  # Clear existing documents

    res = bgg_games_coll.insert_many(bgg_games_records)


    print(f"{len(res.inserted_ids)} documents insérés dans la collection 'bgg_games'.")
    print("Collections disponibles :", but3db.list_collection_names())

#denormalize_bgg_games_into_mongo_dataset()    

def denormalize_activite_into_json():
    with open("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/fichier brut/activite.txt", "r", encoding="utf-8") as f:
        contenu = f.read().strip()


    data = json.loads(contenu)

    with open("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/activite.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print(f"{len(data)} activités ont été enregistrées dans 'activite.json'.")

#denormalize_activite_into_json()

def insertion_activite_into_mongo():
    with open("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/activite.json", "r", encoding="utf-8") as f:
        activites = json.load(f)

    df = pd.DataFrame.from_records(activites)

    df = df.where(pd.notnull(df), None)

    activites_records = df.to_dict(orient="records")

    myclient = MongoClient("mongodb://localhost:27017/")


    but3db = myclient["but3"]


    activite_coll = but3db["activite"]
    activite_coll.delete_many({})  # Clear existing documents

    res = activite_coll.insert_many(activites_records)


    print(f"{len(res.inserted_ids)} documents insérés dans la collection 'activite'.")
    print("Collections disponibles :", but3db.list_collection_names())

#insertion_activite_into_mongo()

def denormalize_movie_into_json():
    df = pd.read_json("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/fichier brut/bd_movies.csv", lines=True)


    colonnes_utiles = [
        "names",
        "genre",
        "overview",
        "score",
        "date_x",
        "crew",
        "orig_lang"
    ]

    vue_voyageurs = df[colonnes_utiles].dropna().reset_index(drop=True)


    vue_voyageurs.to_json("Json/bd_movies_denormalized.json", orient="records", force_ascii=False, indent=4)
    print(f"{len(vue_voyageurs)} films dénormalisés enregistrés dans 'bd_movies_denormalized.json'.")

#denormalize_movie_into_json()



def denormalize_movie_into_mongo():
    df = pd.read_json("C:/Users/Royston/Documents/BUT/SAE5-6/SAE5-6/data/bd_movies.json", lines=True)


    colonnes_utiles = [
        "names",
        "genre",
        "overview",
        "score",
        "date_x",
        "crew",
        "orig_lang"
    ]

    vue_voyageurs = df[colonnes_utiles].dropna().reset_index(drop=True)


    myclient = MongoClient("mongodb://localhost:27017/")


    but3db = myclient["but3"]
    collection = but3db["bd_movies"]


    records = vue_voyageurs.to_dict(orient="records")


    collection.delete_many({})  # (optionnel) vide avant réinsertion
    if records:
        collection.insert_many(records)
        print(f"{len(records)} films dénormalisés insérés dans MongoDB ")
    else:
        print("Aucune donnée à insérer ")


    print("Exemple de document")
    print(collection.find_one()) 

#denormalize_movie_into_mongo()