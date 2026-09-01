using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MerhumAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddOrgHierarchyServiceOfferingsAndUserLinks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_GraveSites_CemeteryId",
                table: "GraveSites");

            migrationBuilder.AddColumn<int>(
                name: "ServiceOfferingId",
                table: "ServiceOrders",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserId",
                table: "Imams",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserId",
                table: "FuneralHomes",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MajlisId",
                table: "Cemeteries",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Muftiates",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Muftiates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ServiceOfferings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FuneralHomeId = table.Column<int>(type: "int", nullable: false),
                    ServiceTypeId = table.Column<int>(type: "int", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceOfferings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceOfferings_FuneralHomes_FuneralHomeId",
                        column: x => x.FuneralHomeId,
                        principalTable: "FuneralHomes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ServiceOfferings_ServiceTypes_ServiceTypeId",
                        column: x => x.ServiceTypeId,
                        principalTable: "ServiceTypes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Majlises",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    MuftiateId = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Majlises", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Majlises_Muftiates_MuftiateId",
                        column: x => x.MuftiateId,
                        principalTable: "Muftiates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ServiceOrders_ServiceOfferingId",
                table: "ServiceOrders",
                column: "ServiceOfferingId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ServiceOrderId_Active",
                table: "Payments",
                column: "ServiceOrderId",
                unique: true,
                filter: "[Status] IN ('Pending', 'Completed')");

            migrationBuilder.CreateIndex(
                name: "IX_Imams_UserId",
                table: "Imams",
                column: "UserId",
                unique: true,
                filter: "[UserId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_GraveSites_CemeteryId_PlotNumber",
                table: "GraveSites",
                columns: new[] { "CemeteryId", "PlotNumber" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FuneralHomes_UserId",
                table: "FuneralHomes",
                column: "UserId",
                unique: true,
                filter: "[UserId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Cemeteries_MajlisId",
                table: "Cemeteries",
                column: "MajlisId");

            migrationBuilder.CreateIndex(
                name: "IX_Majlises_MuftiateId_Name",
                table: "Majlises",
                columns: new[] { "MuftiateId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Muftiates_Name",
                table: "Muftiates",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceOfferings_FuneralHomeId_ServiceTypeId",
                table: "ServiceOfferings",
                columns: new[] { "FuneralHomeId", "ServiceTypeId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceOfferings_ServiceTypeId",
                table: "ServiceOfferings",
                column: "ServiceTypeId");

            migrationBuilder.AddForeignKey(
                name: "FK_Cemeteries_Majlises_MajlisId",
                table: "Cemeteries",
                column: "MajlisId",
                principalTable: "Majlises",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_FuneralHomes_AspNetUsers_UserId",
                table: "FuneralHomes",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Imams_AspNetUsers_UserId",
                table: "Imams",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_ServiceOrders_ServiceOfferings_ServiceOfferingId",
                table: "ServiceOrders",
                column: "ServiceOfferingId",
                principalTable: "ServiceOfferings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Cemeteries_Majlises_MajlisId",
                table: "Cemeteries");

            migrationBuilder.DropForeignKey(
                name: "FK_FuneralHomes_AspNetUsers_UserId",
                table: "FuneralHomes");

            migrationBuilder.DropForeignKey(
                name: "FK_Imams_AspNetUsers_UserId",
                table: "Imams");

            migrationBuilder.DropForeignKey(
                name: "FK_ServiceOrders_ServiceOfferings_ServiceOfferingId",
                table: "ServiceOrders");

            migrationBuilder.DropTable(
                name: "Majlises");

            migrationBuilder.DropTable(
                name: "ServiceOfferings");

            migrationBuilder.DropTable(
                name: "Muftiates");

            migrationBuilder.DropIndex(
                name: "IX_ServiceOrders_ServiceOfferingId",
                table: "ServiceOrders");

            migrationBuilder.DropIndex(
                name: "IX_Payments_ServiceOrderId_Active",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Imams_UserId",
                table: "Imams");

            migrationBuilder.DropIndex(
                name: "IX_GraveSites_CemeteryId_PlotNumber",
                table: "GraveSites");

            migrationBuilder.DropIndex(
                name: "IX_FuneralHomes_UserId",
                table: "FuneralHomes");

            migrationBuilder.DropIndex(
                name: "IX_Cemeteries_MajlisId",
                table: "Cemeteries");

            migrationBuilder.DropColumn(
                name: "ServiceOfferingId",
                table: "ServiceOrders");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Imams");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "FuneralHomes");

            migrationBuilder.DropColumn(
                name: "MajlisId",
                table: "Cemeteries");

            migrationBuilder.CreateIndex(
                name: "IX_GraveSites_CemeteryId",
                table: "GraveSites",
                column: "CemeteryId");
        }
    }
}
