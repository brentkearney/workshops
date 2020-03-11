// ./app/javascript/controllers/member_preview_controller.js
// Copyright (c) 2020 Banff International Research Station.
// This file is part of Workshops. Workshops is licensed under
// the GNU Affero General Public License as published by the
// Free Software Foundation, version 3 of the License.
// See the COPYRIGHT file for details and exceptions.
//

import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "edit" ]

  connect() {
    this.editTarget.textContent = 'Hello, Stimulus!'
  }

  edit() {
    event.preventDefault()
    this.sourceTarget.select()
    console.log("Edit clicked!")
  }
}
