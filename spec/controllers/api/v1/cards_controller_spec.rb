require 'rails_helper'

RSpec.describe Api::V1::CardsController, type: :controller do

  describe "GET #index" do
    before :each do
      current_user = FactoryGirl.create :user
      api_authorization_header current_user.auth_token_for_web

      @label1 = FactoryGirl.create :label, user: current_user
      label2 = FactoryGirl.create :label, user: current_user

      card1 = FactoryGirl.create :card, user: current_user
      card2 = FactoryGirl.create :card, user: current_user

      FactoryGirl.create :label_card, card: card1, label: @label1
      FactoryGirl.create :label_card, card: card2, label: label2
    end

    it "returns all cards" do
      get :index

      expect(json_response[:data].length).to eq 2
      should respond_with 200
    end

    it "returns only the cards of label1" do
      get :index, {label_id: @label1.id}

      expect(json_response[:data].length).to eq 1
      should respond_with 200
    end
  end

  describe "POST #create" do

    it "creates a single card" do
      user = FactoryGirl.create :user
      card_attributes = FactoryGirl.attributes_for :card
      api_authorization_header user.auth_token_for_web

      post :create, simple_card_params(user)

      expect(json_response[:data][:attributes][:title]).to eql card_attributes[:title]
      should respond_with 201
    end

    it "creates a card with relationship to an existing label" do
      user = FactoryGirl.create :user
      label = FactoryGirl.create :label, user: user
      api_authorization_header user.auth_token_for_web

      post :create, card_with_relation_params(user, label)

      expect(json_response[:data][:relationships][:labels][:data][0][:id].to_i).to eql label.id
      should respond_with 201
    end
  end

  describe "DELETE #destroy" do
    it "deletes a card" do
      card = FactoryGirl.create :card
      api_authorization_header card.user.auth_token_for_web 
      
      delete :destroy, { id: card.id }
      
      expect(Card.where(id: card.id).count).to eq 0
      should respond_with 204
    end
  end

  def simple_card_params user
    temp_card = FactoryGirl.create :card, user: user

    serializer = CardSerializer.new temp_card
    adapter = ActiveModel::Serializer::Adapter::JsonApi.new serializer
    temp_card.destroy!

    adapter.serializable_hash.merge({user_id: user.id})
  end

  # {"data":{"attributes":{"side-a":"aaa","side-b":"bbb","proficiency-level":0},"relationships":{"user":{"data":{"type":"users","id":"2"}},"labels":{"data":[{"type":"labels","id":"2"}]}},"type":"cards"}}
  def card_with_relation_params user, label
    temp_card = FactoryGirl.create :card, user: user
    temp_card.label_ids = [label.id]

    serializer = CardSerializer.new temp_card
    adapter = ActiveModel::Serializer::Adapter::JsonApi.new serializer, include: [:labels]
    temp_card.destroy!

    adapter.serializable_hash.merge({user_id: user.id})
  end

  describe "POST #preview_import" do
    it "returns a list of cards in JSON from uploaded CSV file" do
      current_user = FactoryGirl.create :user
      api_authorization_header current_user.auth_token_for_web

      post :preview_import, file: fixture_file_upload('/files/cards_import/without_header.csv', 'text/csv')

      expect(json_response[:cards].length).to eq 4
      expect(json_response[:cards][0][:sideA]).to eq "asd a 1"
      should respond_with 200
    end
  end


  describe "POST #import" do
    it "imports cards from JSON post" do
      current_user = FactoryGirl.create :user
      api_authorization_header current_user.auth_token_for_web

      post :import, {"cards":[{"sideA":"aa","sideB":"bb","proficiencyLevel":"1"},{"sideA":"aa 2","sideB":"bb2","proficiencyLevel":"4"}]}

      expect(current_user.cards.count).to eq 2
      should respond_with 201
    end
  end

end
