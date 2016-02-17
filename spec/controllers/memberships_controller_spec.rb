# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe MembershipsController, type: :controller do

  let(:valid_attributes) { FactoryGirl.attributes_for(:membership).merge(event_id: @event.id, person_id: @person.id) }
  let(:invalid_attributes) { FactoryGirl.attributes_for(:membership, start_time: nil)}

  before do
    # sets @user, @person, @event, @membership
    authenticate_for_controllers
    @user.admin!
  end

  describe "GET #index" do
    it "assigns all memberships as @memberships" do
      get :index, { :event_id => @event.id }
      expect(assigns(:memberships)).to eq([@membership])
    end
  end

  describe "GET #show" do
    it "assigns the requested membership as @membership" do
      get :show, { :event_id => @event.id, :id => @membership.to_param }
      expect(assigns(:membership)).to eq(@membership)
    end
  end

  describe "GET #new" do
    it "assigns a new membership as @membership" do
      get :new, { :event_id => @event.id }
      expect(assigns(:membership)).to be_a_new(Membership)
    end
  end

  describe "GET #edit" do
    it "assigns the requested membership as @membership" do
      get :edit, { :event_id => @event.id, :id => @membership.to_param }
      expect(assigns(:membership)).to eq(@membership)
    end
  end

  # Membership editing is a future feature
# describe "POST #create" do
#
#     before do
#       @new_event = FactoryGirl.create(:event)
#     end
#     context "with valid params" do
#       it "creates a new Membership" do
#         expect {
#           post :create, {:event_id => @new_event.id,
#                          :membership => FactoryGirl.attributes_for(:membership).merge(event_id: @new_event.id, person_id: @person.id)}
#         }.to change(Membership, :count).by(1)
#       end
#
#       it "assigns a newly created membership as @membership" do
#         post :create, {:event_id => @new_event.id,
#                        :membership => FactoryGirl.attributes_for(:membership).merge(event_id: @new_event.id, person_id: @person.id)}
#         expect(assigns(:membership)).to be_a(Membership)
#         expect(assigns(:membership)).to be_persisted
#       end
#
#       it "redirects to the created membership" do
#         post :create, {:event_id => @new_event.id,
#                        :membership => FactoryGirl.attributes_for(:membership).merge(event_id: @new_event.id, person_id: @person.id)}
#         expect(response).to redirect_to(Membership.last)
#       end
#     end
#
#     context "with invalid params" do
#       it "assigns a newly created but unsaved membership as @membership" do
#         post :create, {:event_id => @new_event.id,
#          :membership => FactoryGirl.attributes_for(:membership).merge(event_id: @new_event.id, person_id: @person.id)}
#         expect(assigns(:membership)).to be_a_new(Membership)
#       end
#
#       it "re-renders the 'new' template" do
#         post :create, {:membership => invalid_attributes}
#         expect(response).to render_template("new")
#       end
#     end
#   end
#
#   describe "PUT #update" do
#     context "with valid params" do
#       let(:new_attributes) {
#         skip("Add a hash of attributes valid for your model")
#       }
#
#       it "updates the requested membership" do
#         membership = Membership.create! valid_attributes
#         put :update, {:id => membership.to_param, :membership => new_attributes}
#         membership.reload
#         skip("Add assertions for updated state")
#       end
#
#       it "assigns the requested membership as @membership" do
#         membership = Membership.create! valid_attributes
#         put :update, {:id => membership.to_param, :membership => valid_attributes}
#         expect(assigns(:membership)).to eq(membership)
#       end
#
#       it "redirects to the membership" do
#         membership = Membership.create! valid_attributes
#         put :update, {:id => membership.to_param, :membership => valid_attributes}
#         expect(response).to redirect_to(membership)
#       end
#     end
#
#     context "with invalid params" do
#       it "assigns the membership as @membership" do
#         membership = Membership.create! valid_attributes
#         put :update, {:id => membership.to_param, :membership => invalid_attributes}
#         expect(assigns(:membership)).to eq(membership)
#       end
#
#       it "re-renders the 'edit' template" do
#         membership = Membership.create! valid_attributes
#         put :update, {:id => membership.to_param, :membership => invalid_attributes}
#         expect(response).to render_template("edit")
#       end
#     end
#   end
#
#   describe "DELETE #destroy" do
#     it "destroys the requested membership" do
#       membership = Membership.create! valid_attributes
#       expect {
#         delete :destroy, {:id => membership.to_param}
#       }.to change(Membership, :count).by(-1)
#     end
#
#     it "redirects to the memberships list" do
#       membership = Membership.create! valid_attributes
#       delete :destroy, {:id => membership.to_param}
#       expect(response).to redirect_to(memberships_url)
#     end
#   end
#
end
