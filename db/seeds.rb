# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
# bops1 = Bop.limit(100)
# bops1.each do |bop|
#   bop.dotation = "HT2"
#   bop.save
#   Avi.create(phase: "début de gestion", date_reception: Date.today, date_envoi: Date.today, is_delai: false, is_crg1: true, ae_i: 110, cp_i: 10, etpt_i: 0, t2_i: 0,ae_f: 0, cp_f: 10, etpt_f: 0, t2_f: 0, etat: 'En attente de lecture', statut: "Favorable", commentaire: "OK", bop_id: bop.id, user_id: bop.user_id)
# end
# bops2 = Bop.limit(100).offset(100)
# bops2.each do |bop|
#   bop.dotation = "T2"
#   bop.save
#   Avi.create(phase: "début de gestion", date_reception: Date.today, date_envoi: Date.today, is_delai: false, is_crg1: false, ae_i: 0, cp_i: 0, etpt_i: 11, t2_i: 1000,ae_f: 0, cp_f: 0, etpt_f: 11, t2_f: 1000, etat: 'En attente de lecture', statut: "Favorable", commentaire: "OK",bop_id: bop.id, user_id: bop.user_id)
# end
# bops3 = Bop.limit(100).offset(200)
# bops3.each do |bop|
#   bop.dotation = "T2"
#   bop.save
#   Avi.create(phase: "début de gestion", date_reception: Date.today, date_envoi: Date.today, is_delai: true, is_crg1: false, ae_i: 0, cp_i: 0, etpt_i: 11, t2_i: 1000,ae_f: 0, cp_f: 0, etpt_f: 11, t2_f: 1000, etat: 'Brouillon', statut: "Favorable avec réserve", commentaire: "OK",bop_id: bop.id, user_id: bop.user_id)
# end
# bops4 = Bop.limit(100).offset(300)
# bops4.each do |bop|
#   bop.dotation = "T2"
#   bop.save
#   Avi.create(phase: "début de gestion", date_reception: Date.today, date_envoi: Date.today, is_delai: true, is_crg1: true, ae_i: 0, cp_i: 0, etpt_i: 11, t2_i: 1000,ae_f: 0, cp_f: 0, etpt_f: 11, t2_f: 1000, etat: 'Lu', statut: "Favorable avec réserve", commentaire: "OK",bop_id: bop.id, user_id: bop.user_id)
# end